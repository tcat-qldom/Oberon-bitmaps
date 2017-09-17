# Oberon-bitmaps

![Bitmaps.Mod](Screen0.png?raw=true "Bitmaps.Mod")

# Supported interface
    PROCEDURE New*(w, h, dpt: INTEGER) : Bitmap;
    PROCEDURE Get*(B: Bitmap; x, y: INTEGER): INTEGER;
    PROCEDURE Clear*(B: Bitmap);
    PROCEDURE Dot*(B: Bitmap; col, x, y, mode: INTEGER);
    PROCEDURE Copy*(sB, dB: Bitmap; sx, sy, w, h, dx, dy, mode: INTEGER);
    PROCEDURE CopyBlock*(sB, dB: Bitmap; sx, sy, w, h, dx, dy, mode: INTEGER);
    PROCEDURE CopyPattern*(B: Bitmap; col, pat, x, y, mode: INTEGER);
    PROCEDURE ReplPattern*(B: Bitmap; col, pat, X, Y, W, H, mode: INTEGER);
    PROCEDURE ReplConst*(B: Bitmap; col, x, y, w, h, mode: INTEGER);
    PROCEDURE DisplayBlock*(B: Bitmap; sx, sy, w, h, dx, dy, mode: INTEGER);

# Under development
    PROCEDURE GetPix*(VAR addr: INTEGER; VAR buf: BYTE; depth: INTEGER);
    PROCEDURE PutPix*(VAR addr, border: INTEGER; buf: BYTE; depth: INTEGER);
    PROCEDURE PutLine*(B: Bitmap; VAR data: ARRAY OF INTEGER; x, y, w: INTEGER);
    PROCEDURE GetLine*(B: Bitmap; VAR data: ARRAY OF INTEGER; x, y, w: INTEGER);

# Notes
Bitmaps.Mod makes use of Memory.Mod by Andreas Pirklbauer for heap allocation.
Some raster operattions do not have all modes implemented yet.
To make tests, use test module, BitsTest.Mod, and run:

    BitsTest 52 48 1 ~  BitsTest.Display 30 36 0 ~

    which creates bitmaps of [W]x[H] dimensions with 1-bit depth
    display them at [X][Y] coordinates, with supported mode [0=replace, 1=paint, 2=inverse]
    screen coordinate origin [0,0]=top left corner

