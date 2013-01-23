package grhungary

import (
  "appengine"
  "appengine/datastore"
  "appengine/mail"
  "appengine/user"
  "encoding/json"
  "fmt"
  "io/ioutil"
  "net/http"
  "regexp"
  "strings"
  "text/template"
  "time"
)

var Messages = make(map[string]map[string]string)

func init() {
  http.Handle(
      "/",
      http.RedirectHandler("/client/main.html", http.StatusMovedPermanently))
  http.HandleFunc("/api/rsvp/upsert", handleApiRsvpUpsert);
  http.HandleFunc("/client/main.html", handleClientMain)
  http.HandleFunc("/client/login.html", handleClientLogin)
  http.Handle(
      "/client/",
      http.StripPrefix("/client/", http.FileServer(http.Dir("client"))))
      
  messagesByIdBytes, err := ioutil.ReadFile("messages.json")
  if err != nil {
    panic("Could not read messages.json" + err.Error())
  }

  messagesById := make(map[string]map[string]string)
  err = json.Unmarshal(messagesByIdBytes, &messagesById)
  if err != nil {
    panic("Could not unmarshall messages.json" + err.Error())
  }
  
  for id, msgs := range messagesById {
    for locale, msg := range msgs {
      localeMap, ok := Messages[locale]
      if !ok {
        localeMap = make(map[string]string)
        Messages[locale] = localeMap
      }
      localeMap[id] = msg
    }
  }
}

type Rsvp struct {
  Id string
  PartyMembers []string
  DietaryRestrictions string
  IsStayingOvernight bool
  DurationDaysCount string
  Timestamp time.Time
}

func handleApiRsvpUpsert(w http.ResponseWriter, r *http.Request) {  
  c := appengine.NewContext(r)
  
  buffer := make([]byte, r.ContentLength)
  if _, err := r.Body.Read(buffer); err != nil {
    http.Error(w, err.Error(), http.StatusInternalServerError)
    return
  }
  rsvp := Rsvp{}
  err := json.Unmarshal(buffer, &rsvp)
  if err != nil {
    http.Error(w, err.Error(), http.StatusInternalServerError)
    return
  }
  c.Infof("Received RSVP")
  
  rsvp.Timestamp = time.Now()
  _, err = datastore.Put(c, datastore.NewIncompleteKey(c, "Rsvp", nil), &rsvp)
  if err != nil {
    http.Error(w, err.Error(), http.StatusInternalServerError)
    return
  }
  c.Infof("Stored RSVP for %s", rsvp.Id)
  
  if ok, _ := regexp.MatchString("^[\\w\\.=-_]+@[\\w\\.-_]+\\.[\\w]{2,4}$", rsvp.Id); ok {
  
	  partyMembers := ""
	  for idx := range rsvp.PartyMembers {
	    partyMembers += "<li>" + rsvp.PartyMembers[idx]
	  }
	  
	  body := fmt.Sprintf(`
	      <p>Thank you for responding to our invitation!
	      <p>Here's what we got:</p>
	      <p>
	        <b>Party Members</b>
	        <ul>%s</ul>
	      </p>
	      <p>
	        <b>Dietary Restrictions</b><br/>
	        %s
	      </p>
	      <p>
	        <b>Staying overnight at Mansion Hotel</b>: %t
	      </p>
	      <p>
	        <b>Number of days staying after wedding</b>: %s
	      </p>`,
	      partyMembers,
	      rsvp.DietaryRestrictions,
	      rsvp.IsStayingOvernight,
	      rsvp.DurationDaysCount)
	  
	  msg := mail.Message{
	    Sender: "Gyöngyi & Robert <contact@grhungary.com>",
	    ReplyTo: "contact@grhungary.com",
	    To: []string{rsvp.Id},
	    Subject: "Wedding Response Received",
	    HTMLBody: body,
	  }
	  if err = mail.Send(c, &msg); err != nil {
	    c.Errorf("Couldn't send mail to %s: %s", rsvp.Id, err.Error());
	    http.Error(w, err.Error(), http.StatusInternalServerError)
	    return
	  }
	  
	  msg.To = []string{"contact@grhungary.com"}
	  mail.Send(c, &msg)
	  
	  c.Infof("Sent mail to %s", rsvp.Id);
  }

  w.Header().Set("Content-type", "text/json; charset=utf-8")
  encoder := json.NewEncoder(w)
  encoder.Encode(rsvp)
}

func GetRsvp(c appengine.Context, userId string) (
    rsvp *Rsvp, rsvpKey *datastore.Key, err error) {
  guestPartyKey := datastore.NewKey(c, "GuestParty", userId, 0, nil)
  query := datastore.NewQuery("Rsvp").Ancestor(guestPartyKey).Limit(1)
  count, err := query.Count(c)
  if err != nil || count == 0 {
    return
  }
  it := query.Run(c)
  rsvp = new(Rsvp)
  rsvpKey, err = it.Next(rsvp)
  return
}

func GetUserIdAndEmail(c appengine.Context, r *http.Request) (
    userId string, userEmail string) {
  u := user.Current(c)
  if u != nil {
    userId = u.ID
    userEmail = u.Email
  } else if emailCookie, _ := r.Cookie("email"); emailCookie != nil {
    userId = emailCookie.Value
    userEmail = emailCookie.Value
  }
  return
}

type MainData struct {
  Messages map[string]string
}

type LoginData struct {
  LoginUrl string
  Messages map[string]string
}

func handleClientMain(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("Content-type", "text/html; charset=utf-8")
  mainData := MainData{
    Messages: GetLocaleMap(r),
  }
  
  tpl, _ := template.ParseFiles("client/main.html")
  tpl.ExecuteTemplate(w, "main", mainData)
}

func handleClientLogin(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("Content-type", "text/html; charset=utf-8")
  c := appengine.NewContext(r)
  userId, _ := GetUserIdAndEmail(c, r)
  if userId != "" {
    http.Redirect(w, r, "/client/main.html", http.StatusFound)
    return
  }
  url, _ := user.LoginURL(c, "/")
  tpl, _ := template.ParseFiles("client/login.html")
  tpl.ExecuteTemplate(w, "login", LoginData{LoginUrl: url})
}

func GetLocaleMap(r *http.Request) map[string]string {
  var hasHu bool
  locales := strings.Split(r.Header.Get("Accept-Language"), ",")
  for idx := range locales {
    hasHu = hasHu || strings.ToLower(locales[idx]) == "hu"
  }
  if hasHu {
    return Messages["hu"]
  }
  return Messages["en_US"]
}
