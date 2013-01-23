part of grhungary;

class Decoration {
  double DURATION = 12000.0;
  CanvasElement _canvas;
  double _startTime;
  double _prevTime;
  List<Entity> _entities = new List<Entity>();
  int _frameRequest = null;
  int _width;
  int _height;

  void start() {
    if (_frameRequest != null) {
      window.cancelAnimationFrame(_frameRequest);
    }
    _width = query("body").offsetWidth;
    _height = 400;
    _canvas = query("#decoration-canvas");
    _canvas.width = _width;
    _canvas.height = _height;
    CanvasRenderingContext2D ctx = _canvas.context2d;
    ctx.translate(0, _height);
    ctx.scale(1, -1);
    ctx.fillStyle = "#CC0000";
    ctx.strokeStyle = "#AA0000";
    _startTime = new Date.now().millisecondsSinceEpoch * 1.0;
    _prevTime = _startTime;
    _entities.add(new Vine(new Point(0, 364), .15, 0.0));
    _frameRequest = window.requestAnimationFrame(_renderFrame);
  }

  void _renderFrame(double _) {
    double timestamp = new Date.now().millisecondsSinceEpoch * 1.0;
    double totalTimeFrac = (timestamp - _startTime) / DURATION;
    CanvasRenderingContext2D ctx = _canvas.context2d;
    if (totalTimeFrac > 1.0) {
      ctx.restore();
      return;
    }
    double deltaTime = timestamp - _prevTime;
    _prevTime = timestamp;
    ctx.clearRect(0, 0, 800, 400);
    _entities.forEach((entity) {
      entity.render(ctx, totalTimeFrac, deltaTime);
    });
    _frameRequest = window.requestAnimationFrame(_renderFrame);
  }
}

abstract class Entity {
  void render(CanvasRenderingContext2D ctx, double totalTimeFrac, double deltaTime);
}

class Vine extends Entity {
  double MIN_THICKNESS = 2.0; // pixels

  List<Point> _positions;
  double _initialVelocity;
  double _initialBearing;
  double _velocity;
  double _bearing;
  double _globalBearing;
  double _length;

  Vine(Point initialPosition, double initialVelocity, double initialBearing) :
      _positions = new List<Point>(),
      _initialVelocity = initialVelocity,
      _initialBearing = initialBearing,
      _velocity = initialVelocity,
      _bearing = initialBearing,
      _globalBearing = initialBearing,
      _length = 0.0 {
    _positions.add(initialPosition);
  }

  void render(CanvasRenderingContext2D ctx, double totalTimeFrac, double deltaTime) {
    _growTrunk(ctx, totalTimeFrac, deltaTime);
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(_positions.first.x, _positions.first.y);
    double lengthSoFar = 0.0;
    for (int i = 0; i < _positions.length - 1; i++) {
      lengthSoFar += distanceTo(_positions[i], _positions[i + 1]);
      ctx.lineWidth = MIN_THICKNESS +
          4.0 * ((_length - lengthSoFar) / _length);
      ctx.lineTo(_positions[i + 1].x, _positions[i + 1].y);
      ctx.stroke();
    }
    ctx.restore();
  }

  void _growTrunk(CanvasRenderingContext2D ctx, double totalTimeFrac, double deltaTime) {
    _bearing = _globalBearing + (PI / 8) * sin(2 * PI * 4 * totalTimeFrac + _globalBearing);
    _velocity = _initialVelocity * organicAttenuation(totalTimeFrac, a: 3.25);
    double deltaX = deltaTime * _velocity * cos(_bearing);
    double deltaY = deltaTime * _velocity * sin(_bearing);
    Point currPos = _positions.last;
    Point newPosition = new Point(currPos.x + deltaX, currPos.y + deltaY);
    _length = _length + distanceTo(currPos, newPosition);
    _positions.add(newPosition);
  }
}

/**
 * @param {number} x A number from 0 to 1.
 * @param {number} a Attentuation factor.
 * @return {number} A number from 0 to 1 monotonically decreasing on a Gaussian scale.
 */
double organicAttenuation(double x, {double a: 1.0}) {
  return pow(E, -pow(x, 2) * a);
}

double distanceTo(Point fromPoint, Point toPoint) {
  return sqrt(pow(toPoint.y - fromPoint.y, 2) + pow(toPoint.x - fromPoint.x, 2));
}
