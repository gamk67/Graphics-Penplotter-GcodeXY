# NAME

GcodeXY - Produce gcode files for pen plotters from Perl

# SYNOPSIS

    use Graphics::Penplotters::GcodeXY;
    # create a new GcodeXY object
    $g = new Graphics::Penplotters::GcodeXY( papersize => "A4", units => "in");
    # draw some lines and other shapes
    $g->line(1,1, 1,4);
    $g->box(1.5,1, 2,3.5);
    $g->polygon(1,1, 1,2, 2,2, 2,1, 1,1);
    # write the output to a file
    $g->output("file.gcode");

# DESCRIPTION

`GcodeXY` provides a method for generating gcode for pen plotters (hence the XY)
from Perl. It has graphics primitives that allow arcs, lines, polygons, and rectangles to
be drawn as line segments. Units used can be specified ("mm" or "in" or "pt").
The default unit is an inch, which is used internally. Other units are scaled accordingly.
The only gcode commands generated are G00 and G01. Fonts are supported, SVG input is possible,
and Postscript output can be generated as well.

# DEPENDENCIES

This module requires `Math::Bezier`, and `Math::Trig`. For SVG import you will
need `Image::SVG::Transform` and `XML::Parser` and `Image::SVG::Path` and `POSIX` and
`List::Util` and `Font::FreeType`.

# CONSTRUCTOR

- `new(options)`

    Create a new GcodeXY object. The different options that can be set are:

    - check

        Print the bounding box of the gcode design; report on what page sizes it would fit;
        present an estimate of the distance to pen has to move on and off the paper; report
        on the number of pen cycles.

    - curvepts

        Set the number of sampling points for curves, default 50. This can be overridden for each
        individual curve. The number is reduced for small curves.

    - hatchsep

        Specifies the spacing of the hatching lines.

    - hatchangle

        Specifies the angle of the hatching lines in degrees.  `0` (the default)
        gives horizontal lines; `90` gives vertical lines; `45` gives diagonal
        lines running from lower-left to upper-right.  Positive values rotate the
        lines counter-clockwise.

    - header

        Specifies a header to be inserted at the start of the output file. The default is
        `G20\nG90\nG17\nF 50\nG92 X 0 Y 0 Z 0\nG00 Z 0\n` which specifies, respectively,
        use inches (change to G21 for mm), absolute distance mode, use the XY plane only,
        a feedrate of 50 inches per minute (change this if you use other units, or if you are impatient),
        and use the current head position as the origin. The last command is the penup command,
        which **must** terminate the header.

    - id

        This is an identifying string, useful when you have several objects in your program.
        Some diagnostics will print the id.

    - margin

        This number indicates a percentage of whitespace that is to be maintained around the page,
        when using the `split` method. This is useful, for example, to stop the pen from overshooting
        the edge, cause damage to the paper, or allow glueing together of several sheets. This number will be
        doubled, all coordinates will be reduced by this percentage, and the whole page will be centered,
        creating the margin on all sides.

    - opt\_debug

        Enable debugging output from the optimizer. Useful only to the developer of this module.

    - optimize

        This flag controls the internal peephole optimizer. The default is 1 (ON). Setting it to 0
        switches it off, which may be necessary in some cases, but this may of course result in very
        inefficient execution.

    - outfile

        The name of the file to which the generated gcode is to be written.

    - papersize

        The size of paper to use, if `xsize` or `ysize` are not defined. This allows
        a document to easily be created using a standard paper size without having to
        remember the size of paper. Valid choices are the usual ones such as
        `A3`, `A4`, `A5`, and `Letter`, but the full range is available. Used to warn about
        out-of-bound movement. The `xsize` and `ysize` will be set accordingly.

    - penupcmd

        Lifts the pen off the paper. The default is `G00 Z 0\n`.

    - pendowncmd

        Lowers the pen onto the paper. The default is `G00 Z 0.2\n`. The distance
        of 0.2 inches (i.e. 5 mm) is highly dependent on the plotter and its setup,
        so this may well have to be adjusted. 

    - trailer

        Specifies a trailer to be inserted at the end of the output file. The default is
        `G00 Z 0\nG00 X 0 Y 0\n` which lifts the pen and returns it to the origin.

    - units

        Units that are to be used in the file. Currently supported are `mm`, `in`, `pc`, `cm`, `px`
        and `pt`.

    - warn

        Generate a warning if an instruction would take the pen outside the boundary specified
        with the `papersize` or the `xsize` or `ysize` variables. It is a fatal error if either
        one has not been specified.

    - xsize

        Specifies the width of the drawing area in units. Used to warn about out-of-bound
        movement.

    - ysize

        Specifies the height of the drawing area in units. Used to warn about out-of-bound
        movement.

    Example:

            $ref = new Graphics::Penplotters::GcodeXY( xsize  => 4,
                            ysize      => 3,
                            units      => "in",
                            warn       => 1,
                            check      => 1,
                            pendowncmd => "G00 Z 0.1\n");

# OBJECT METHODS

Unless otherwise specified, object methods return 1 for success or 0 in some
error condition (e.g. insufficient arguments).

- addcomment(string)

    Add a comment to the output. The string will be enclosed in round brackets and a newline
    will be added. The current path is not flushed first. This command is useful mainly for
    debugging. Note that comments will likely cause the optimizer to be less effective.

- addfontpath(string, \[string, ...\])

    Add location(s) to search for fonts to the set of builtin paths. This should be an absolute
    pathname. The default search path specifies the local directory, the user's private .fonts
    directory, and the global font directory in /usr/share/fonts. You will probably have to use
    this function if you want to use LaTeX fonts.

- addtopage(string)

    Inserts the `string`, which should be a gcode command or a comment. In case of a comment,
    the string should be enclosed in round brackets. Use with care, needless to say. The string
    is inserted directly into the output stream, after the current path has been flushed, so
    you are also responsible for making sure that each line is terminated by a newline.
    Please note that you may have to adjust the `currentpoint` after using this command.

- arc(x, y, r, a, b \[, number\])

    Draws an arc (i.e. part of a circle). This requires an x coordinate, a y coordinate,
    a radius, a starting angle and a finish angle. The pen will be moved to the start point.
    The optional number overrides the default number of sampling points, and is used in this call only.

- arcto(x1, y1, x2, y2, r)

    Starting from the current position, draw a line to (`x1`,`y1`) and then to (`x2`,`y2`),
    but generate a "shortcut" with an arc of radius `r`, making a rounded corner. This command is
    equivalent to the Postscript instruction of the same name.

- arrowhead(length, width \[, type\])

    Draw an arrowhead, i.e. two or three small lines, normally at the end of a line segment. The
    direction and position of the arrowhead is derived from the last line segment on the current
    path. If the path is empty, the current point is used for the position, and the direction will
    be horizontal and towards increasing x-coordinate. The type can be 'open' (which causes two
    backwards directed lines to be drawn), or 'closed' (where also a line across is drawn).

- box(x1,y1 \[, x2,y2\])

    Draw a rectangle from lower left co-ordinates (`x1`,`y1`) to upper right co-ordinates (`y2`,`y2`).
    If just two parameters are passed, the current position is assumed to be the lower left hand corner.
    The pen will be lifted first, a fast move will be executed to (`x1`,`y1`), and the pen will be
    lowered. The sides of the rectangle will then be drawn.

    Example:

        $g->box(10,10, 20,30);

    Note: the `polygon` method is far more flexible, but this method is more convenient.

- boxR(x,y)

    Draw a rectangle from the current position to the relative upper right co-ordinates (`x`,`y`).

    Example:

        $g->boxR(2,3);

- boxround(r, x1,y1, x2,y2)

    Draw a rectangle from lower left co-ordinates (`x1`,`y1`) to upper right co-ordinates (`y2`,`y2`),
    using rounded corners as determined by the radius perameter `r`. The pen will be lifted first,
    a fast move will be executed to the midpoint of the bottom edge, and the pen will be lowered.
    The sides and arcs of the rectangle will then be drawn in a clockwise direction.

    Example (pt units):

        $g->boxround(20, 100,100, 200,300);

- circle(x, y, r \[, number\])

    Draws a circular arc. This requires an x coordinate, a y coordinate,and a radius.
    The pen will be moved to the start point. The required number of sampling points is estimated
    based on the value of the radius. The optional `number` overrides this number of sampling points,
    and is used in this call only. The current point is left at (`x`+`r`,`y`).

- ($x, $y) = currentpoint()

    Returns the current location of the pen in user coordinates. It is also possible to pass two
    parameters to this method, in which case the current point is set to that position.

- curve(points)

    Calculates a Bezier curve using the array of `points`. The pen will be moved to the start point.
    The number of sampling points is determined by `curvepoints` which can be set during creation
    of the GcodeXY object. For quadratic and cubic curves, the optimal number of sampling points
    will be calculated automatically.

- curveto(points)

    Calculates a Bezier curve using the array of `points`, starting from the current position.
    The number of sampling points is determined by `curvepoints` which can be set during creation
    of the GcodeXY object. For quadratic and cubic curves, the optimal number of sampling points
    will be calculated automatically.

- ellipse(x, y, a , b \[, number\])

    Draws an ellipse. This requires an x coordinate, a y coordinate, a horizontal width and
    a vertical width. The pen will be moved to the start point. The required number of sampling points
    is estimated based on the value of the radius. The optional `number` overrides this number of
    sampling points, and is used in this call only.

- getsegpath()

    Get a copy of the current segment path. This returns an array of hashes containing the start and end
    points of the segments.
    Example:
        @points = getsegpath();

- grestore()

    Restore the previous graphics state, which should have been saved with `gsave`.

- gsave()

    Save the current graphics state (e.g. paths, current transformation matrix) onto the graphics stack.

- importsvg(filename)

    Imports an SVG file. Your mileage may vary with this one - not the entire SVG spec (900 pages!)
    is implemented. If you get warnings about this, the result may well be be incorrect, especially
    with `use` and `defs` tags. Just one layer is implemented. The good news is that the 'vpype'
    software produces simple SVG output that is 100% compatible, so if you do get problems try
    vpype with the '--linesort' option or similar.

    All the graphics shapes are implemented, as well as paths and transforms. Note that some SVGs
    contain clever tricks that may result in incorrect displays. SVG designs use a different
    coordinate system (top down) from the one used in this module. It is therefore essential to
    save and restore the graphics state around this function, and also to scale and rotate 
    the svg to an appropriate size and orientation. Here is a typical example:

            $g->gsave();                  # save the current graphics state
            $g->initmatrix();             # start a new, pristine graphics state
            $g->translate($my_x, $my_y);  # move to page location where the svg must appear
            $g->rotate($my_degrees);      # rotate the coordinate system as required
            $g->scale($my_scale);         # scale the svg as required, negative creates mirror image
            $g->importsvg('myfile.svg');  # finally import the svg
            $g->grestore();               # restore the previous graphics state

    Note that exporting SVG from GcodeXY generates a full page SVG, so no translation or rotation 
    will be needed. 

- initmatrix()

    Reset the Current Transformation Matrix (CTM) to the unit matrix, thereby cancelling all previous
    `translate`, `rotate`, `scale` and `skew` operations.

- line(x1,y1, x2,y2)

    Draws a line from the co-ordinates (`x1`,`y1`) to (`x2`,`y2`). The pen will be lifted first,
    a fast move will be executed to (x1,y1), and the pen will be lowered. Then a slow move
    to (x2,y2) is performed.

    Example:

        $g->line(10,10, 10,20);

- lineR(x,y)

    Draws a line from the current position (cx,cy) to (cx+`x`,cy+`y`), i.e. relative coordinates.
    The pen is assumed to be lowered.

    Example:

        $g->lineR(2,1);

- moveto(x,y)

    Inserts gcode to move the pen to the specified location. The pen will be lifted first, and
    lowered at the destination.

- movetoR(x,y)

    Inserts gcode to move the pen to the specified location using relative displacements.
    You should not normally need this command, unless you insert your own code. The pen will be
    lifted first, and lowered at the destination.

- newsegpath()

    Initialize the segment path, used for hatching. This is done automatically for fonts and for 
    all the built-in shapes. Use this function if you define your own series of shapes.

- output(\[filename\])

    Writes the current gcode out to the file named `filename`, or, if not specified, to the
    filename specified using `outfile` when the gcode object was created. This will destroy
    any existing file of the same name. Use this method whenever output to file is required.
    The current gcode document in memory is not cleared, and can still be extended. If the
    `check` flag is set, some statistics are printed, including the bounding box.

- exporteps(filename)

    Writes the current gcode out to the file named `filename` in the form of encapsulated
    Postscript. This will destroy any existing file of the same name. The current gcode document
    in memory is not cleared, and can still be extended. If the `check` flag is set, the bounding
    box is printed.

- exportsvg(filename)

    Writes the current gcode out to the file named `filename` in the form of a full page SVG file.
    This will destroy any existing file of the same name. The current gcode document in memory is
    not cleared, and can still be extended. If the `check` flag is set, the bounding box is printed.
    The boundingbox is returned (bottom left x and y, and top right x and y).

- pageborder(margin)

    Create a border round the page, with a `margin` specified in current units.

- pendown()

    Inserts the pendown command, causing the pen to be lowered onto the paper.

- penup()

    Inserts the penup command, causing the pen to be lifted from the paper.

- polygon\_clip(x1,y1, x2,y2, ..., xn,yn)

    Add a polygon to an internal clipping queue for hidden-line removal. Polygons added
    with `polygon_clip` are not immediately emitted to the current path; instead they are
    kept in a queue. When a new polygon overlaps previously queued polygons, any parts
    of the previously queued polygons that lie underneath the new polygon are removed.

    The method accepts the same parameters as `polygon` (a list of coordinate pairs).
    Returns 1 on success.

- polygon\_clip\_end()

    Flush the internal clipping queue into the current segment path. Remaining visible
    segments from previously queued polygons are emitted into the current path using
    the existing `_addpath` mechanism (moveto/lineto entries). The clip queue is
    cleared. Returns 1 on success.

- polygon(x1,y1, x2,y2, ..., xn,yn)

    The `polygon` method is multi-function, allowing many shapes to be created and
    manipulated. The pen will be lifted first, a fast move will be executed to (`x1`,`y1`),
    and the pen will be lowered. Lines will then be drawn from (`x1`,`y1`) to (`x2`,`y2`) and
    then from (`x2`,`y2`) to (`x3`,`y3`) up to (`xn-1`,`yn-1`) to (`xn`,`yn`).

    Example:

        # draw a square with lower left point at (10,10)
        $g->polygon(10,10, 10,20, 20,20, 20,10, 10,10);

- polygonR(x1,y1, x2,y2, ..., xn,yn)

    This method is multi-function, allowing many shapes to be created and manipulated relative
    to the current position (cx,cy). The pen is assumed to be lowered. Lines will then be drawn
    to (cx+`x1`,cy+`y1`), then to (cx+`x2`,cy+`y2`), and so on.

    Example:

        # draw a square with lower left point at (10,10)
        $g->polygonR(1,1, 1,2, 2,2, 2,1, 1,1);

- polygonround(r, x1,y1, x2,y2, x3,y3, ..., xn,yn)

    Draws a polygon starting from the current position, using absolute coordinates, with rounded
    corners between the line segments whose radius is determined by `r`. Lines with rounded corners
    will then be drawn from (`x1`,`y1`) to (`x2`,`y2`), and so on. Specify at least three pairs
    of coordinates (i.e. two line segments).

    Example:

        # draw a square with lower left point at (10,10)
        $g->polygonround(20, 100,200, 200,200, 200,100, 100,100);

- rotate(degrees \[, refx, refy\])

    Rotate the coordinate system by `degrees`. If the optional reference point (`refx`,`refy`) is
    not specified, the origin is assumed.

- scale(sx \[, sy \[, refx, refy\]\])

    Scale the coordinate system by `sx` in the x direction and `sy` in the y direction.
    If `sy` is not specified it is assumed to be the same as `sx`. If the optional reference
    point (`refx`,`refy`) is not specified, the origin is assumed. Negative parameters will
    cause the direction of movement to be reversed.

- $face = setfont(name, size)

    Tries to locate the font called `name`, and returns a `face` object if successful. This object
    is then used for subsequent rendering using `stroketext`. Note that the `size` parameter has
    to be in points, which is the unit used by the Freetype library (and is, indeed, the standard
    everywhere). It is not advisable to use any other unit when rendering text.

- setfontsize(size)

    Set the default fontsize to be used for rendering to `size`. See the caveat under `setfont`:
    if you must use other units than 'pt', it is your responsibility to scale the size appropriately.

- sethatchsep(width)

    When hatching, the space between hatch lines is set to `width`.

- sethatchangle(degrees)

    Set the angle of the hatch lines.  `0` (the default) gives horizontal
    lines; `90` gives vertical lines.  See also the `hatchangle` constructor
    argument.

- skewX(degrees)

    Schedule a skew (also called shear) in the X direction. This operation works relative to the
    origin, so a suitable `translate` operation may be required first, otherwise the results might
    be unexpected.

- skewY(degrees)

    Schedule a skew (also called shear) in the Y direction. This operation works relative to the
    origin, so a suitable `translate` operation may be required first, otherwise the results might
    be unexpected.

- split(size, filestem)

    Split the current sheet into smaller sized sheets, and write the results into separate files.
    `size` is, for example, "A4". The `filestem` prefix will be extended with the sheet numbers,
    for example, foo\_0\_0.gcode, foo\_0\_1.gcode, etc.

- stroke()

    Render the current path, i.e. translate the path into gcode.

- strokefill()

    Render the current path, i.e. translate the path into gcode, and fill it with a hatch pattern.

- stroketext(face, string)

    Render a `string` using the `face` object returned by `setfont`. To render a character code,
    use "chr(charcode)" instead of "string". A `stroke` operation is applied after each character.

- stroketextfill(face, string)

    Render a `string` using the `face` object returned by `setfont`. To render a character code,
    use "chr(charcode)" instead of "string". A `stroke` operation is applied after each character.
    Each character is filled with a hatch pattern. 

- $w = textwidth(face, string)

    Calculate the width of a `string` using the `face` object returned by `setfont`. The returned
    value is in page coordinates, i.e. the value is not subject to current transformations.

- translateC()

    Move the origin of the coordinate system to the current location, as returned by `currentpoint`.

- translate(x,y)

    Move the origin of the coordinate system to (`x`,`y`). Both parameters are locations specified
    in the current coordinate system, and are thus subjected to rotation and scaling.

- $v = vpype\_linesort()

    Sends the current design to vpype in order to sort the line segments in such a way that pen travel
    is minimized. Needless to say, vpype needs to be installed and on your path. A new graphics 
    object is returned containing the optimized path. This command will be very useful when hatching
    of fonts and other shapes has been performed. In the process, two temporary files will be created
    and destroyed.

# 3D METHODS

## SYNOPSIS

    $g->gsave();                              # saves both 2-D and 3-D state
    $g->initmatrix3();                        # reset 3-D CTM
    $g->translate3(50, 50, 0);                # move 3-D origin
    $g->rotate3(axis => [0,0,1], deg => 45);  # spin around Z
    $g->scale3(10);                           # uniform scale

    my $m = $g->sphere(0, 0, 0, 1, 12, 24);   # UV sphere mesh
    my $s = $g->flatten_to_2d($m);            # project to 2-D edge list
    $g->draw_polylines($s);                   # draw via host pen hooks

    $g->grestore();
    $g->output('myplot.gcode');

## CTM and transforms

- initmatrix3()

    Reset the 3-D CTM to identity.

- translate3($tx, $ty \[, $tz\])

    Pre-multiply the 3-D CTM by a translation.

- translateC3()

    Move the 3-D origin to the current 3-D position, then reset the position
    to (0,0,0).

- scale3($sx \[, $sy \[, $sz\]\])

    Pre-multiply by a scale matrix.  If `$sy`/`$sz` are omitted they default
    to `$sx` (uniform scale).

- rotate3(axis => \[$ax,$ay,$az\], deg => $angle)

    Pre-multiply by a rotation around an arbitrary axis.

- rotate3\_euler($rx, $ry, $rz \[, $order\])

    Pre-multiply by a sequence of axis-aligned rotations.  `$order` is a
    three-character string such as `'XYZ'` (default).

- compose\_matrix($aref, $bref)

    Multiply two 4x4 matrices; returns a new matrix ref.  Neither input is
    modified.

- invert\_matrix($mref)

    Invert a 4x4 matrix (Gauss-Jordan with partial pivoting).  Returns a matrix
    ref, or `undef` if the matrix is singular.

## 3-D current point

- currentpoint3()

    Return the current 3-D position as a list `($x, $y, $z)`.

- currentpoint3($x, $y, $z)

    Set the current 3-D position.

## Point transformation

- transform\_point($pt\_ref)

    Transform a point (arrayref `[$x,$y,$z]`) through the current CTM3.
    Returns `($tx, $ty, $tz)`.

- transform\_points($pts\_ref)

    Transform an arrayref of points; returns an arrayref of `[$tx,$ty,$tz]`.

## 3-D drawing primitives

- moveto3($x, $y \[, $z\])

    Lift the pen, fast-move to the projected 2-D position, lower pen.

- movetoR3($dx, $dy \[, $dz\])

    Relative `moveto3` from the current 3-D position.

- line3($x1,$y1,$z1 \[, $x2,$y2,$z2\])

    Six-arg form: move to start, draw to end.
    Three-arg form: draw from the current position.

- lineR3($dx, $dy \[, $dz\])

    Relative line from the current 3-D position.

- polygon3(x1,y1,z1, ...)

    Move to the first triple, draw through the remaining triples.

- polygon3C(x1,y1,z1, ...)

    Like `polygon3` but automatically closes back to the first point.

- polygon3R(dx1,dy1,dz1, ...)

    Like `polygon3` but each triple is relative to the preceding point.

## Wireframe solid drawing (draw directly, no mesh returned)

- box3($x1,$y1,$z1, $x2,$y2,$z2)

    Draw a wireframe axis-aligned box between two opposite corners.

- cube($cx,$cy,$cz,$side)

    Draw a wireframe cube centred at `(cx,cy,cz)`.

- axis\_gizmo($cx,$cy,$cz \[, $len \[, $cone\_r \[, $cone\_h\]\]\])

    Draw three labelled axis arrows (X, Y, Z) as wireframe lines with small
    arrow cones.  `$len` is the total axis length (default 1).  The cone
    radius and height default to 5% and 15% of `$len` respectively.

## Mesh-returning solid primitives

All of the following return a mesh structure
`{ verts => \@v, faces => \@f }` which can be passed to
`flatten_to_2d`, `hidden_line_remove`, `mesh_to_obj`, etc.

- mesh($verts\_ref, $faces\_ref)

    Low-level constructor.  Build a mesh from existing arrays.

- prism($cx,$cy,$cz, $w,$h,$d)

    Axis-aligned rectangular prism (box) centred at `(cx,cy,cz)`, with
    dimensions `w` (X), `h` (Y), `d` (Z).  A cube is `prism` with
    `w == h == d`.  Returns a closed 12-face triangulated mesh.

- sphere($cx,$cy,$cz, $r \[, $lat \[, $lon\]\])

    UV-sphere mesh.  `$lat` and `$lon` control the tessellation density
    (defaults 12 and 24).

- icosphere($cx,$cy,$cz, $r \[, $subdivisions\])

    Icosphere mesh built by repeated midpoint subdivision of a regular
    icosahedron.  `$subdivisions` defaults to 2 (320 faces).  Produces a more
    uniform tessellation than `sphere`.

- cylinder($base\_ref, $top\_ref, $r \[, $seg\])

    Cylinder mesh.  `$base_ref` and `$top_ref` are `[$x,$y,$z]` centre
    points.  Side walls only; no end caps.

- frustum($cx,$cy,$cz, $r\_bot,$r\_top,$height \[, $seg\])

    General truncated cone (frustum) centred at `(cx,cy,cz)`.  Both end caps
    are included.  When `$r_top == 0` this is a cone; when
    `$r_bot == $r_top` it is a closed cylinder.

- cone($cx,$cy,$cz, $r,$height \[, $seg\])

    Convenience wrapper: `frustum` with `r_top = 0`.

- capsule($cx,$cy,$cz, $r,$height \[, $seg\_r \[, $seg\_h\]\])

    Cylinder with hemispherical end caps.  `$height` is the length of the
    cylindrical body (not counting the caps).  `$seg_r` is the number of
    radial segments (default 16); `$seg_h` is the number of latitudinal
    segments per hemisphere (default 8).

- plane($cx,$cy,$cz, $w,$h \[, $segs\_w \[, $segs\_h\]\])

    Flat rectangular mesh in the XY plane, centred at `(cx,cy,cz)`.
    Dimensions `$w` x `$h`; subdivided into `$segs_w` x `$segs_h` quads.
    Useful for floors, billboards, and UI surfaces.

- torus($cx,$cy,$cz, $R,$r \[, $maj\_seg \[, $min\_seg\]\])

    Torus mesh in the XY plane.  `$R` is the major radius (centre of tube to
    centre of torus); `$r` is the minor radius (tube radius).  Defaults:
    24 major segments, 12 minor segments.

- disk($cx,$cy,$cz, $r \[, $seg\])

    Flat circular disk mesh in the XY plane.  Fan-triangulated from the centre.
    Vertex 0 is the centre; vertices `1..$seg` are the rim.

- pyramid($cx,$cy,$cz, $r,$height \[, $sides\])

    Regular-polygon-base pyramid.  `(cx,cy,cz)` is the base centre; `$r` is
    the base circumradius; `$height` is the height in +Z.  `$sides` defaults
    to 4 (square pyramid).  The base cap is included.

## Quaternions

- quat\_from\_axis\_angle($axis\_ref, $deg)

    Return a unit quaternion `[$w,$x,$y,$z]`.

- quat\_to\_matrix($q)

    Convert a quaternion to a 4x4 rotation matrix.

- quat\_slerp($q1, $q2, $t)

    Spherical linear interpolation (0 <= t <= 1).

## Mesh utilities

- bbox3($mesh\_or\_pts)

    Returns `([$minx,$miny,$minz], [$maxx,$maxy,$maxz])`.

- compute\_normals($mesh)

    Compute face and averaged vertex normals in-place; returns `$mesh`.

## Visibility

- backface\_cull($mesh \[, view\_dir => \\@dir\])

    Return arrayref of visible face indices.  Default view direction `[0,0,-1]`.

- occlusion\_clip($mesh \[, res => N\])

    Z-buffer rasterisation; returns arrayref of `[[p1,p2],...]` edge segments.

- hidden\_line\_remove($mesh \[, %opts\])

    Back-face cull then occlusion clip; returns edge segments.

## 2-D output

- flatten\_to\_2d($mesh\_or\_polylines)

    Project mesh edges or pass-through polylines; returns `[[$p1,$p2],...]`.

- draw\_polylines($segs\_ref)

    Emit segments via the host's pen hooks; calls `stroke()` at the end.

- project\_to\_svg($obj \[, %opts\])

    Return an SVG string of the projected edges.

## Mesh I/O

- mesh\_to\_obj($mesh \[, $name\])

    Serialise to ASCII OBJ string.

- mesh\_from\_obj($str)

    Parse an ASCII OBJ string; returns a mesh.

- mesh\_to\_stl($mesh \[, $name\])

    Serialise to ASCII STL string.

- mesh\_from\_stl($str)

    Parse an ASCII STL string; returns a mesh (vertices are de-duplicated).

## Numeric configuration

- set\_tolerance($eps)>, get\_tolerance()

    Set/get the floating-point equality tolerance (default 1e-9).

- set\_units($units)

    Store a units tag (e.g. `'mm'`); no automatic scaling is applied.

- set\_coordinate\_convention(handedness => ..., euler\_order => ...)

    Store convention tags for downstream use.

## Mesh representation

All solid primitives that return a mesh use the structure:

    { verts => \@v, faces => \@f }

where `@v` is an array of `[$x,$y,$z]` position arrayrefs and `@f` is
an array of `[$i0,$i1,$i2]` triangle index arrayrefs.  Winding order is
counter-clockwise when viewed from the outside (right-hand normal pointing
outward).

# BUGS AND LIMITATIONS

As noted above, the SVG specification (900 pages) is only partially implemented, and just one layer
can be used. I suspect that diagnostics about pen travel distance may not always be correct.
Layering is not supported officially, but can be simulated.

# SEE ALSO

[Graphics::Penplotter::GcodeXY::Geometry2D](https://metacpan.org/pod/Graphics%3A%3APenplotter%3A%3AGcodeXY%3A%3AGeometry2D),
[Graphics::Penplotter::GcodeXY::Geometry3D](https://metacpan.org/pod/Graphics%3A%3APenplotter%3A%3AGcodeXY%3A%3AGeometry3D),
[Graphics::Penplotter::GcodeXY::Postscript](https://metacpan.org/pod/Graphics%3A%3APenplotter%3A%3AGcodeXY%3A%3APostscript),
[Graphics::Penplotter::GcodeXY::SVG](https://metacpan.org/pod/Graphics%3A%3APenplotter%3A%3AGcodeXY%3A%3ASVG),
[Graphics::Penplotter::GcodeXY::Split](https://metacpan.org/pod/Graphics%3A%3APenplotter%3A%3AGcodeXY%3A%3ASplit),
[Graphics::Penplotter::GcodeXY::Hatch](https://metacpan.org/pod/Graphics%3A%3APenplotter%3A%3AGcodeXY%3A%3AHatch),
[Graphics::Penplotter::GcodeXY::Font](https://metacpan.org/pod/Graphics%3A%3APenplotter%3A%3AGcodeXY%3A%3AFont),
[Graphics::Penplotter::GcodeXY::Vpype](https://metacpan.org/pod/Graphics%3A%3APenplotter%3A%3AGcodeXY%3A%3AVpype),
[Graphics::Penplotter::GcodeXY::Optimize](https://metacpan.org/pod/Graphics%3A%3APenplotter%3A%3AGcodeXY%3A%3AOptimize)

# AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com).

# LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
