package grhungary

import (
  "appengine"
  "appengine/datastore"
  "appengine/mail"
  "bytes"
  "encoding/json"
  "log"
  "net/http"
  "net/url"
  "regexp"
  "strings"
  "html/template"
  "time"
)

var EMAIL_REGEXP = "^[\\w\\.=-_]+@[\\w\\.-_]+\\.[\\w]{2,4}$"

var tpl *template.Template

func stringEquals(arg1 string, arg2 string) bool {
  return arg1 == arg2
}

func init() {
  http.HandleFunc("/api/rsvp/create", handleApiRsvpCreate);
  http.HandleFunc("/ie", handleIe)
  http.HandleFunc("/", handleRoot)

  var err error
  tpl, err = template.New("tpl").
      Funcs(template.FuncMap{"stringEquals": stringEquals}).
      ParseGlob("template/*")
  if err != nil {
    log.Fatal("Couldn't parse templates: ", err.Error())
    return
  }
}

type Rsvp struct {
  Id string
  PartyMembers []string
  DietaryRestrictions string
  IsStayingOvernight bool
  InterestedInSightseeing string
  Timestamp time.Time
  IsAccepted bool
}

type EmailBody struct {
  Rsvp Rsvp
  IsHu bool
}

func handleApiRsvpCreate(w http.ResponseWriter, r *http.Request) {
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
  rsvpKey := datastore.NewIncompleteKey(c, "Rsvp", nil)
  if _, err = datastore.Put(c, rsvpKey, &rsvp); err != nil {
    http.Error(w, err.Error(), http.StatusInternalServerError)
    c.Errorf("Error storing RSVP for %s", rsvp.Id)
    return
  }
  c.Infof("Stored RSVP for %s", rsvp.Id)

  isEmail, _ := regexp.MatchString(EMAIL_REGEXP, rsvp.Id);  
  if rsvp.IsAccepted && isEmail {
    isHu := GetIsHu(r)

    emailBodyBuf := bytes.Buffer{}
    tpl.ExecuteTemplate(&emailBodyBuf, "rsvp-email-body", EmailBody{
      IsHu: isHu,
      Rsvp: rsvp,
    })
    emailSubjectBuf := bytes.Buffer{}
    tpl.ExecuteTemplate(&emailSubjectBuf, "rsvp-email-subject", isHu)

    msg := mail.Message{
      Sender: "Gyöngyi & Robert <contact@grhungary.com>",
      ReplyTo: "contact@grhungary.com",
      To: []string{rsvp.Id},
      Subject: emailSubjectBuf.String(),
      HTMLBody: emailBodyBuf.String(),
    }
    if err = mail.Send(c, &msg); err != nil {
      c.Errorf("Couldn't send mail to %s: %s", rsvp.Id, err.Error());
      http.Error(w, err.Error(), http.StatusInternalServerError)
      return
    }

    c.Infof("Sent mail to %s", rsvp.Id);
  }

  // Send feedback email.
  emailBodyBuf := bytes.Buffer{}
  if rsvp.IsAccepted {
    tpl.ExecuteTemplate(&emailBodyBuf, "rsvp-feedback-accept-email", rsvp)
  } else {
    tpl.ExecuteTemplate(&emailBodyBuf, "rsvp-feedback-reject-email", rsvp)
  }
  msg := mail.Message{
    Sender: "Gyöngyi & Robert <contact@grhungary.com>",
    To: []string{"contact@grhungary.com"},
    Subject: "RSVP Received",
    HTMLBody: emailBodyBuf.String(),
  }
  if err = mail.Send(c, &msg); err != nil {
    c.Errorf("Couldn't send feedback mail: %s", err.Error());
    http.Error(w, err.Error(), http.StatusInternalServerError)
    return
  }

  w.Header().Set("Content-type", "text/json; charset=utf-8")
  encoder := json.NewEncoder(w)
  encoder.Encode(rsvp)
}

type MainData struct {
  IsHu bool
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
  if strings.Contains(r.UserAgent(), "MSIE") {
    newUrl, _ := url.Parse(r.URL.String())
    newUrl.Path = "/ie"
    http.Redirect(w, r, newUrl.String(), http.StatusFound)
    return
  }
  if r.URL.Path != "/" {
    newUrl, _ := url.Parse(r.URL.String())
    newUrl.Path = "/"
    http.Redirect(w, r, newUrl.String(), http.StatusFound)
    return
  }
  w.Header().Set("Content-type", "text/html; charset=utf-8")
  tpl.ExecuteTemplate(w, "main", MainData{IsHu: GetIsHu(r)})
}

func handleIe(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("Content-type", "text/html; charset=utf-8")
  tpl.ExecuteTemplate(w, "ie", MainData{IsHu: GetIsHu(r)})
}

func GetIsHu(r *http.Request) bool {
  var hasHu bool
  if r.FormValue("lang") != "" {
    return r.FormValue("lang") == "hu"
  }
  locales := strings.Split(r.Header.Get("Accept-Language"), ",")
  for idx := range locales {
    hasHu = hasHu || strings.ToLower(locales[idx]) == "hu"
  }
  return hasHu
}
