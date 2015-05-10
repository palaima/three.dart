library three.extras.cloth;

import 'dart:math' as math;
import 'package:three/three.dart';

const double DAMPING = 0.03;
const double DRAG = 1 - DAMPING;
const double MASS = .1;
const double restDistance = 25.0;

const double GRAVITY = 981 * 1.4;
final Vector3 gravity = new Vector3(0.0, -GRAVITY, 0.0)..scale(MASS);

const double TIMESTEP = 18 / 1000;
const double TIMESTEP_SQ = TIMESTEP * TIMESTEP;

class Cloth extends Mesh {
  List<int> pins = [];

  bool wind = true;
  double windStrength = 2.0;
  Vector3 windForce = new Vector3.zero();

  bool sphereVisible = false;
  Vector3 ballPosition = new Vector3(0.0, -45.0, 0.0);
  double ballSize = 60.0; //40

  Vector3 tmpForce = new Vector3.zero();

  int lastTime;

  List<ClothParticle> particles = [];
  List<List> constrains = [];

  Cloth._(DynamicGeometry geometry, Material material, int w, int h, Function clothFunction)
      : super(geometry, material) {
    // Create particles
    for (var v = 0; v <= h; v++) {
      for (var u = 0; u <= w; u++) {
        particles.add(new ClothParticle(u / w, v / h, 0.0, MASS, clothFunction));
      }
    }

    index(u, v) => u + v * (w + 1);

    // Structural

    for (var v = 0; v < h; v++) {
      for (var u = 0; u < w; u++) {
        constrains.add([particles[index(u, v)], particles[index(u, v + 1)], restDistance]);
        constrains.add([particles[index(u, v)], particles[index(u + 1, v)], restDistance]);
      }
    }

    for (var u = w, v = 0; v < h; v++) {
      constrains.add([particles[index(u, v)], particles[index(u, v + 1)], restDistance]);
    }

    for (var v = h, u = 0; u < w; u++) {
      constrains.add([particles[index(u, v)], particles[index(u + 1, v)], restDistance]);
    }
  }

  factory Cloth(Material clothMaterial, [int widthSegments = 10, int heightSegments = 10]) {
    var clothFunction = (u, v) {
      var x = (u - 0.5) * (restDistance * widthSegments);
      var y = (v + 0.5) * (restDistance * heightSegments);
      return new Vector3(x, y, 0.0);
    };

    var clothGeometry = new DynamicGeometry.fromGeometry(
        new ParametricGeometry(clothFunction, widthSegments, heightSegments));

    return new Cloth._(clothGeometry, clothMaterial, widthSegments, heightSegments, clothFunction);
  }

  Vector3 diff = new Vector3.zero();

  void _satisifyConstrains(ClothParticle p1, ClothParticle p2, double distance) {
    diff.subVectors(p2.position, p1.position);
    var currentDist = diff.length;
    if (currentDist == 0) return; // prevents division by 0
    var correction = diff.scale(1 - distance / currentDist);
    var correctionHalf = correction.scale(0.5);
    p1.position.add(correctionHalf);
    p2.position.sub(correctionHalf);
  }

  void simulate(int time) {
    if (lastTime == null) {
      lastTime = time;
      return;
    }

    // Aerodynamics forces
    if (wind) {
      var faces = geometry.faces;

      for (var i = 0; i < faces.length; i++) {
        var face = faces[i];
        var normal = face.normal;

        tmpForce
          ..setFrom(normal)
          ..normalize()
          ..scale(normal.dot(windForce));

        particles[face.a].addForce(tmpForce);
        particles[face.b].addForce(tmpForce);
        particles[face.c].addForce(tmpForce);
      }
    }

    for (var i = 0; i < particles.length; i++) {
      particles[i]
        ..addForce(gravity)
        ..integrate(TIMESTEP_SQ);
    }

    // Start Constrains
    for (var i = 0; i < constrains.length; i++) {
      var constrain = constrains[i];
      _satisifyConstrains(constrain[0], constrain[1], constrain[2]);
    }

    // Ball Constrains

    ballPosition.z = -math.sin(new DateTime.now().millisecondsSinceEpoch / 600) * 90; //+ 40;
    ballPosition.x = math.cos(new DateTime.now().millisecondsSinceEpoch / 400) * 70;

    if (sphereVisible) {
      for (var i = 0; i < particles.length; i++) {
        var particle = particles[i];
        var pos = particle.position;
        diff.subVectors(pos, ballPosition);

        if (diff.length < ballSize) {
          // collided
          diff.normalize().scale(ballSize);
          pos.setFrom(ballPosition).add(diff);
        }
      }
    }

    // Floor Constains
    for (var i = 0; i < particles.length; i++) {
      if (particles[i].position.y < -250) {
        particles[i].position.y = -250.0;
      }
    }

    // Pin Constrains
    for (var i = 0; i < pins.length; i++) {
      var xy = pins[i];
      var p = particles[xy];
      p.position.setFrom(p.original);
      p.previous.setFrom(p.original);
    }
  }
}

class ClothParticle {
  Vector3 position; // position
  Vector3 previous; // previous
  Vector3 original;

  Vector3 a = new Vector3.zero(); // acceleration

  double invMass;

  Vector3 tmp = new Vector3.zero();
  Vector3 tmp2 = new Vector3.zero();

  ClothParticle(double x, double y, double z, double mass, clothFunction) {
    position = clothFunction(x, y);
    previous = clothFunction(x, y);
    original = clothFunction(x, y);
    invMass = 1 / mass;
  }

  // Force -> Acceleration
  void addForce(Vector3 force) {
    a.add(tmp2
      ..setFrom(force)
      ..scale(invMass));
  }

  // Performs verlet integration
  void integrate(double timesq) {
    var newPos = tmp.subVectors(position, previous);
    newPos.scale(DRAG).add(position);
    newPos.add(a.scale(timesq));

    tmp = previous;
    previous = position;
    position = newPos;

    a.setZero();
  }
}
