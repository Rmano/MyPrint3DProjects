/*==============================================================================
    SliderVertuo.scad
    Copyright (c) 2026 Romano Giannetti

    Author:
        Romano Giannetti

    License:
        Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)

        You are free to:
            - Share: copy and redistribute the material
            - Adapt: remix, transform, and build upon the material

        Under the following terms:
            - Attribution: credit must be given to the author
            - NonCommercial: no commercial use permitted
            - ShareAlike: derivatives must use the same license

        Full license text:
            https://creativecommons.org/licenses/by-nc-sa/4.0/

==============================================================================*/
$fn = 60;
// $vpr = [325, 50, 280];
// $vpd = 900;
// $vpt = [90, 100, -40];

// Main parameters

N = 5;             // vertical sliders
M = 3;             // horizontal sliders
phi_hangholes = 6; // put hang holes in the next-to-last stand if N > 2, M > 1; 0 to inhibit
have_base = 1;     // if it is 0, remove the base; only logical if you have hang holes

// Slider data

phi_interno = 48;   // internal diameter of the Vertuo capsule
phi_externo = 57.5; // external diameter of the Vertuo capsule
phi_extra = 1;      // extra diameter
l_extra = 4;        // minimum extension of the "quasi-cylinder"
border_x = 4;       // depth border
border_y = 10;      // border between horizontal rows
thickness = 4;      // thickness of the sliders and the base
edge = 2.5;         // "step" in the slider
pest_len = 25;      // size of the tab

// Structure: N upward, M sideways

pillar_thickness = 8; // size of the columns
slider_angle = 10;    // tilt of the "slider"
slider_distance = 40; // distance between sliders; the maximum height of the Vertuo is 33 mm
base_thickness = 6;
base_border = 8;      // if == 0, solid

// Size of the "slot" (hole with borders) and position in the Y direction of the center.
// Notice the 1 here: no need to have the X border on the external side.
size_x = 1 * border_x + (phi_externo + phi_extra + l_extra);
size_y = 2 * border_y + (phi_externo + phi_extra);
pos_y = border_y + (phi_externo + phi_extra) / 2;

// Cylinder with an added straight area of size s at the center.
// The cylinders become cones if cone != 0.
module casi_cylinder(h = 10, r = 10, s = l_extra, cone = 0) {
    radio = r;
    thick = h;

    if (cone == 0) {
        translate([-s / 2, 0, 0])
            cylinder(h = h, r = r, center = false);

        translate([+s / 2, 0, 0])
            cylinder(h = h, r = r, center = false);

        translate([-s / 2, -r, 0])
            cube([s, 2 * r, h]);
    } else {
        translate([-s / 2, 0, 0])
            cylinder(h = h, r1 = r, r2 = r - cone, center = false);

        translate([+s / 2, 0, 0])
            cylinder(h = h, r1 = r, r2 = r - cone, center = false);

        // Chamfered cube. At the bottom the cube is s x 2r; at the top, s-cone x 2(r-cone).
        ca_points = [
            [0, 0, 0],
            [s, 0, 0],
            [s, 2 * r, 0],
            [0, 2 * r, 0],
            [0, cone, h],
            [s, cone, h],
            [s, 2 * r - cone, h],
            [0, 2 * r - cone, h]
        ];
        ca_faces = [
            [0, 1, 2, 3], // bottom
            [4, 5, 1, 0], // front
            [7, 6, 5, 4], // top
            [5, 6, 2, 1], // right
            [6, 7, 3, 2], // back
            [7, 4, 0, 3]  // left
        ];

        translate([-s / 2, -r, 0])
            polyhedron(ca_points, ca_faces);
    }
}

// Quasi-cylinder with chamfered edges.
module pestanha(h = 5, w = 20, l = 40, c = 0) {
    r = w / 2;
    s = l - 2 * r;

    assert(s >= 0, "La longitud de la pestaña no puede ser menos que la anchura");

    rotate(90)
        difference() {
            casi_cylinder(h, r, s, c);
        }
}

module slider_rect() {
    difference() {
        cube([size_x, size_y, thickness]);

        center_x = border_x + (2 * phi_externo + phi_extra + l_extra) / 2;
        center_y = border_y + (phi_externo + phi_extra) / 2;

        translate([center_x, center_y, thickness - edge])
            casi_cylinder(
                h = edge + 1,
                r = 0.5 * (phi_externo + phi_extra),
                s = phi_externo
            );

        translate([center_x, center_y, -10])
            casi_cylinder(
                h = thickness + 20,
                r = 0.5 * (phi_interno + phi_extra),
                s = phi_interno
            );
    }
}

module slider_full() {
    slider_rect();

    // Add the tab.
    translate([5, pos_y, thickness - 0.1])
        pestanha(h = 2, w = 10, l = pest_len, c = 2);
}

module slider_stand() {
    difference() {
        union() {
            rotate([0, 90 - slider_angle, 0])
                slider_full();

            // Fill the chamfer.
            cube([thickness, pos_y * 2, 1]);
        }
    }
}

module stand_of_sliders() {
    for (i = [1:N]) {
        translate([slider_distance * (i - 1), 0, 0])
            slider_stand();
    }

    // Build the base and the pillars.
    // Pillars.
    translate([0, 0, -pillar_thickness + 1])
        cube([
            slider_distance * (N - 1) + thickness,
            pillar_thickness,
            pillar_thickness
        ]);

    translate([0, 2 * pos_y - pillar_thickness, -pillar_thickness + 1])
        cube([
            slider_distance * (N - 1) + thickness,
            pillar_thickness,
            pillar_thickness
        ]);

    // Base.
    if (have_base > 0) {
        blen = size_x * cos(slider_angle);

        difference() {
            translate([thickness - base_thickness - 1, 0, -blen + 1])
                cube([base_thickness, 2 * pos_y, blen]);

            // Lighten the base.
            if (base_border > 0) {
                translate([thickness - base_thickness - 1.2, 2 * base_border, -blen])
                    cube([
                        base_thickness + 2,
                        2 * pos_y - 4 * base_border,
                        blen - 2 * base_border
                    ]);
            }
        }
    }
}

module full_stand() {
    difference() {
        for (i = [1:M]) {
            translate([0, 2 * (pos_y - pillar_thickness / 2) * (i - 1), 0])
                stand_of_sliders();
        }

        // Hanging holes.
        if ((N > 2) && (M > 1) && (phi_hangholes > 0)) {
            translate([
                    slider_distance * (N - 2) - thickness,
                    2 * (pos_y - pillar_thickness / 2) * M - phi_hangholes,
                    -phi_hangholes
                ])
                rotate([0, 90, 0])
                    cylinder(r = phi_hangholes / 2, h = 3 * thickness);

            translate([
                    slider_distance * (N - 2) - thickness,
                    pillar_thickness + phi_hangholes,
                    -phi_hangholes
                ])
                rotate([0, 90, 0])
                    cylinder(r = phi_hangholes / 2, h = 3 * thickness);
        }
    }
}

// intersection() {
full_stand();
// slider_stand();
// slider_full();

// Central section.
// translate([0, pos_y / 2, 0]) color("red")
//     cube([50, pos_y, 20], center = true);

// Central hole.
// translate([100, center_y, 0]) color("red")
//     cube([70, 70, 50], center = true);
// }
