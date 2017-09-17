MODULE Bitmaps; (*TK 16.9.2017*)
IMPORT SYSTEM, Kernel, Memory, Display, Texts, Oberon;

CONST
  dbw = 1024 (*Display.width*) DIV 8; (* nbr of bytes aross display line *)

TYPE
  Bitmap* = POINTER TO BitmapDesc;
  BitmapDesc* = RECORD
    width*, height*, depth*: INTEGER;
    base*: INTEGER;
    size*: INTEGER
  END;

VAR
  W: Texts.Writer;

PROCEDURE New*(w, h, dpt: INTEGER) : Bitmap;
  VAR b: Bitmap;
BEGIN
  NEW(b); IF b # NIL THEN
    b.width := w; b.height := h; b.depth := dpt;
    b.size := ((w+31+w MOD 32) DIV 32)*4 * h; (*bitmap size in bytes, word aligned*)
    Memory.New(SYSTEM.VAL(Memory.Pointer, b.base), b.size);
    IF b.base = 0 THEN b := NIL END
  END
RETURN b END New;

PROCEDURE Get*(B: Bitmap; x, y: INTEGER): INTEGER;
  VAR ofs, wd: INTEGER; bt: BYTE;
BEGIN
  ofs := y*B.width + x; SYSTEM.GET(B.base + ofs, bt);
  wd :=  bt;
RETURN wd END Get;

PROCEDURE Clear*(B: Bitmap);
 VAR adr, size: INTEGER;
BEGIN
  size := B.size;  adr := B.base;
  WHILE size > 0 DO
    (* 0101.. bit pattern for tests *)
    SYSTEM.PUT(adr, SYSTEM.VAL(INTEGER, 0AAAAAAAAH));
    (*SYSTEM.PUT(adr, SYSTEM.VAL(INTEGER, 0));*)
    INC(adr, 4);  DEC(size, 4)
  END
END Clear;

PROCEDURE Dot*(B: Bitmap; col, x, y, mode: INTEGER);
  VAR a, w, bw: INTEGER; u, s: SET;
BEGIN w := B.width;
    bw := ((w+31+w MOD 32) DIV 32)*4;   (* number of bytes on bitmap line, word aligned *)
  a := B.base + y*bw + (x DIV 32)*4;        (* address of bitmap word *)
    s := {x MOD 32}; SYSTEM.GET(a, u);

    IF mode = Display.paint THEN SYSTEM.PUT(a, u + s)
    ELSIF mode = Display.invert THEN SYSTEM.PUT(a, u / s)
    ELSE (*mode = replace*)
      IF col = Display.black THEN SYSTEM.PUT(a, u + s) ELSE SYSTEM.PUT(a, u - s) END
    END

END Dot;

(* CopyPLine - Copy pattern line in paint mode *)

PROCEDURE CopyPLine(x, src, dst, w: INTEGER);
  VAR bt: BYTE; wd: INTEGER; pix: SET;   
BEGIN

  SYSTEM.GET(src, bt); INC(src); wd := bt;
  IF w > 8 THEN SYSTEM.GET(src, bt); INC(src); wd := bt*100H + wd;
    IF w > 16 THEN SYSTEM.GET(src, bt); INC(src); wd := bt*10000H + wd;
      IF w > 24 THEN SYSTEM.GET(src, bt); INC(src); wd := bt*1000000H + wd END
    END
  END;

  (*wd := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, wd)*{0..w MOD 32});*)

  SYSTEM.GET(dst, pix);
  SYSTEM.PUT(dst, SYSTEM.VAL(SET, LSL(wd, x MOD 32)) + pix);

  IF x MOD 32  > 0 THEN
    SYSTEM.GET(dst+4, pix); wd := ASR(wd, -(x MOD 32));
    SYSTEM.PUT(dst+4, SYSTEM.VAL(SET, wd)(*{0..x MOD 32-1}*) + pix)
  END

END CopyPLine;

(* ReplBLine0 - Replicate bitmap line in replace mode *)

PROCEDURE ReplBLine0(col, x, dst, w: INTEGER);
  VAR x0, w0, wd: INTEGER; pix: SET;   
BEGIN
 
  (* (pix * {maskleft*8..31} * {0..maskright*8-1}) *)

  w0 :=  w MOD 32; x0 := x MOD 32;
  WHILE w > 0 DO

    (* paint black *)
    DEC(w, 32); wd := -1;
    IF w < 0 THEN wd := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, wd)*{0..w0}) END;
  
    SYSTEM.GET(dst, pix);
    SYSTEM.PUT(dst, SYSTEM.VAL(SET, LSL(wd, x0)) + pix);
     
    IF x0 > 0 THEN
      SYSTEM.GET(dst+4, pix); wd := ASR(wd, -(x0));
      SYSTEM.PUT(dst+4, SYSTEM.VAL(SET, wd)*{0..x0-1} + pix)
    END; (* black *)

    (* invert white *)
    IF col=Display.white THEN
      wd := -1;
      IF w < 0 THEN wd := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, wd)*{0..w0}) END;

      SYSTEM.GET(dst, pix);
      SYSTEM.PUT(dst, SYSTEM.VAL(SET, LSL(wd, x0)) / pix);
    
      IF x0 > 0 THEN
        SYSTEM.GET(dst+4, pix); wd := ASR(wd, -(x0));
        SYSTEM.PUT(dst+4, SYSTEM.VAL(SET, wd)*{0..x0-1} / pix)
      END
    END; INC(dst, 4) (* white *)

  END
END ReplBLine0;

(* CopyBLine0 - Copy bitmap line in replace mode *)

PROCEDURE CopyBLine0(x, src, dst, w: INTEGER);
  VAR w0, x0, wd: INTEGER; pix: SET;   
BEGIN
 
  (* (pix * {maskleft*8..31} * {0..maskright*8-1}) *)

  w0 :=  w MOD 32; x0 := x MOD 32;
  WHILE w > 0 DO

    (*paint black line*)
    DEC(w, 32); wd := -1;
    IF w < 0 THEN wd := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, wd)*{0..w0}) END;
  
    SYSTEM.GET(dst, pix);
    SYSTEM.PUT(dst, SYSTEM.VAL(SET, LSL(wd, x0)) + pix);

    IF x0 > 0 THEN
      SYSTEM.GET(dst+4, pix); wd := ASR(wd, -(x0));
      SYSTEM.PUT(dst+4, SYSTEM.VAL(SET, wd)*{0..x0-1} + pix)
    END; (*black*)

    (*invert white=clear*)
    wd := -1;
    IF w < 0 THEN wd := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, wd)*{0..w0}) END;

    SYSTEM.GET(dst, pix);
    SYSTEM.PUT(dst, SYSTEM.VAL(SET, LSL(wd, x0)) / pix);

    IF x0 > 0 THEN
      SYSTEM.GET(dst+4, pix); wd := ASR(wd, -(x0));
      SYSTEM.PUT(dst+4, SYSTEM.VAL(SET, wd)*{0..x0-1} / pix)
    END; (*white*)

    (*paint bitmap line*)
    SYSTEM.GET(src, wd); INC(src, 4);
    IF w < 0 THEN wd := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, wd)*{0..w0}) END;

    SYSTEM.GET(dst, pix);
    SYSTEM.PUT(dst, SYSTEM.VAL(SET, LSL(wd, x0)) + pix);

    INC(dst, 4);
    IF x0 > 0 THEN
      SYSTEM.GET(dst, pix); wd := ASR(wd, -(x0));
      SYSTEM.PUT(dst, SYSTEM.VAL(SET, wd)*{0..x0-1} + pix)
    END (*bitmap line*)
 
  END
END CopyBLine0;

(* CopyBLine1 - Copy bitmap line in paint mode *)

PROCEDURE CopyBLine1(x, src, dst, w: INTEGER);
  VAR w0, wd: INTEGER; pix: SET;   
BEGIN
 
  (* (pix * {maskleft*8..31} * {0..maskright*8-1}) *)

  w0 :=  w MOD 32; 
  WHILE w > 0 DO

    SYSTEM.GET(src, wd); INC(src, 4); DEC(w, 32);
    IF w < 0 THEN wd := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, wd)*{0..w0}) END;

    SYSTEM.GET(dst, pix);
    SYSTEM.PUT(dst, SYSTEM.VAL(SET, LSL(wd, x MOD 32)) + pix);
      
    INC(dst, 4);
    IF x MOD 32 > 0 THEN
      SYSTEM.GET(dst, pix); wd := ASR(wd, -(x MOD 32));
      SYSTEM.PUT(dst, SYSTEM.VAL(SET, wd)*{0..x MOD 32-1} + pix)
    END
 
  END
END CopyBLine1;


(* CopyBLine2 - Copy bitmap line in invert mode *)

PROCEDURE CopyBLine2(x, src, dst, w: INTEGER);
  VAR w0, wd: INTEGER; pix: SET;   
BEGIN
 
  (* (pix * {maskleft*8..31} * {0..maskright*8-1}) *)

  w0 :=  w MOD 32; 
  WHILE w > 0 DO

    SYSTEM.GET(src, wd); INC(src, 4); DEC(w, 32);
    IF w < 0 THEN wd := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, wd)*{0..w0}) END;

    SYSTEM.GET(dst, pix);
    SYSTEM.PUT(dst, SYSTEM.VAL(SET, LSL(wd, x MOD 32)) / pix);
      
    INC(dst, 4);
    IF x MOD 32 > 0 THEN
      SYSTEM.GET(dst, pix); wd := ASR(wd, -(x MOD 32));
      SYSTEM.PUT(dst, SYSTEM.VAL(SET, wd)*{0..x MOD 32-1} / pix)
    END
 
  END
END CopyBLine2;

PROCEDURE CopyBlock*(sB, dB: Bitmap; sx, sy, w, h, dx, dy, mode: INTEGER);
  VAR w0, bw, src, dst: INTEGER;
BEGIN w0 := sB.width;
  bw := ((w0+31+w0 MOD 32) DIV 32)*4;   (* number of bytes on bitmap line, word aligned *)
  src := sB.base + sy*bw + (sx DIV 32)*4;     (* source bottom left bitmap byte *);
  dst := dB.base + dy*bw + (dx DIV 32)*4;   (* destination *)

    IF mode = Display.invert THEN
      REPEAT
        CopyBLine2(dx, src, dst, w);
        DEC(h);  INC(src, bw);  INC(dst, bw)
      UNTIL h = 0
    ELSIF mode = Display.paint THEN
      REPEAT
        CopyBLine1(dx, src, dst, w);
        DEC(h);  INC(src, bw);  INC(dst, bw)
      UNTIL h = 0
    ELSIF mode = Display.replace THEN
      REPEAT
        CopyBLine0(dx, src, dst, w);   
        DEC(h);  INC(src, bw);  INC(dst, bw)
      UNTIL h = 0
    END
  
END CopyBlock;

PROCEDURE CopyPattern*(B: Bitmap; col, pat, x, y, mode: INTEGER);
  VAR dst: INTEGER; w, h, pw, bw: BYTE;
BEGIN
  SYSTEM.GET(pat, w); SYSTEM.GET(pat+1, h); INC(pat, 2);

  pw := (w+7) DIV 8;  (* bytes in pattern line *)
  bw := ((B.width+31+B.width MOD 32) DIV 32)*4;   (* bytes in bitmap line, word aligned *)
  dst := B.base + y*bw + (x DIV 32)*4;  (* bottom left address of bitmap raster *)

  REPEAT  (* loop over h lines *)
    CopyPLine(x, pat, dst, w (*, col, mode*));
    DEC(h);  INC(dst, bw);  INC(pat, pw)
  UNTIL h = 0
    
END CopyPattern;

PROCEDURE ReplPattern*(B: Bitmap; col, pat, X, Y, W, H, mode: INTEGER);
  VAR x, y, pat0, dst: INTEGER; w, h, h0, nx, ny, pw, bw: BYTE;
BEGIN
  SYSTEM.GET(pat, w); SYSTEM.GET(pat+1, h); INC(pat, 2);
  h0 := h; pat0 := pat;

  pw := (w+7) DIV 8;  (* bytes in pattern line *)
  bw := ((B.width+31+B.width MOD 32) DIV 32)*4;   (* bytes in bitmap line, word aligned *)
  ny := Y+((B.height-Y) DIV H)*H;    (* number of patterns to fit vertically in bitmap*)
  nx := X+((B.width-X) DIV W)*W; (* number of patterns to fit horizontally in bitmap*)

  y := Y; WHILE y < ny DO        (* copy `ny' rows of patterns upwards, spanned by H pixels *)
    x := X; WHILE x < nx DO    (* copy `nx' patterns horizontally rightwards, spanned by W pixels*)
      dst := B.base + y*bw + (x DIV 32)*4;    (* bottom left address of bitmap raster, shifted by W pixels each step*)
    REPEAT  (* loop over h lines *)
      CopyPLine(x, pat, dst, w (*, col, mode*));
      DEC(h);  INC(dst, bw);  INC(pat, pw)
      UNTIL h = 0;
      h := h0; pat := pat0; INC(x, W)
    END; INC(y, H)
  END

END ReplPattern;

PROCEDURE ReplConst*(B: Bitmap; col, x, y, w, h, mode: INTEGER);
  VAR w0, bw, dst: INTEGER;
BEGIN
  w0 := B.width;
  bw := ((w0+31+w0 MOD 32) DIV 32)*4;  (* number of bytes on bitmap line, word aligned *)
  dst := B.base + y*bw + (x DIV 32)*4;        (* bottom left address of bitmap raster *)
  IF mode = Display.replace THEN
    REPEAT
      ReplBLine0(col, x, dst, w);
      DEC(h);  INC(dst, bw)
    UNTIL h = 0
  END
END ReplConst;

(* modified from Display.ReplConst*)
(*PROCEDURE ReplConst*(B: Bitmap; col, x, y, w, h, mode: INTEGER);
    VAR al, ar, a0, a1, w0, bw: INTEGER; left, right, mid, pix, pixl, pixr: SET;
  BEGIN 
    w0 := B.width;
    bw := ((w0+31+w0 MOD 32) DIV 32)*4;  (* number of bytes on bitmap line, word aligned *)
    al := B.base + y*bw;
    ar := ((x+w-1) DIV 32)*4 + al; al := (x DIV 32)*4 + al;
    IF ar = al THEN
      mid := {(x MOD 32) .. ((x+w-1) MOD 32)};
      a1 := al; WHILE a1 < al + (h-1)*bw DO
        SYSTEM.GET(a1, pix);
        IF mode = Display.invert THEN SYSTEM.PUT(a1, pix / mid)
        ELSIF (mode = Display.replace) & (col = Display.black) THEN (*erase*) SYSTEM.PUT(a1, pix - mid)
        ELSE (* (mode = paint) OR (mode = Display.replace) & (col # Display.black) *) SYSTEM.PUT(a1, pix + mid)
        END; INC(a1, bw)
      END
    ELSIF ar > al THEN
      left := {(x MOD 32) .. 31}; right := {0 .. ((x+w-1) MOD 32)};
      a0 := al; WHILE a0 < al + (h-1)*bw DO
        SYSTEM.GET(a0, pixl); SYSTEM.GET(ar, pixr);
        IF mode = Display.invert THEN
          SYSTEM.PUT(a0, pixl / left);
          FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.GET(a1, pix); SYSTEM.PUT(a1, -pix) END ;
          SYSTEM.PUT(ar, pixr / right)
        ELSIF (mode = Display.replace) & (col = Display.black) THEN (*erase*)
          SYSTEM.PUT(a0, pixl - left);
          FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.PUT(a1, {}) END ;
          SYSTEM.PUT(ar, pixr - right)
        ELSE (* (mode = paint) OR (mode = replace) & (col # black) *)
          SYSTEM.PUT(a0, pixl + left);
          FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.PUT(a1, {0 .. 31}) END ;
          SYSTEM.PUT(ar, pixr + right)
        END ;
        INC(ar, bw); INC(a0, bw);
      END
    END
  END ReplConst;*)

PROCEDURE DisplayBlock*(B: Bitmap; sx, sy, w, h, dx, dy, mode: INTEGER);
  VAR bw, src, dst: INTEGER;
BEGIN
  bw := ((w+31+w MOD 32) DIV 32)*4; (* number of bytes on bitmap line, word aligned *)
  src := B.base; (*Texts.WriteInt(W, pw, 6); Texts.WriteLn(Wr);*)
  dy := Display.Height-dy-h; (* convert dy to screen coordinate 0,0 = bottom,left *)
  dst := Display.Base + dy*dbw + (dx DIV 32)*4;  (* addr bottom left byte *)

  IF mode = Display.invert THEN
    REPEAT
      CopyBLine2(dx, src, dst, w);
      DEC(h);  INC(src, bw);  INC(dst, dbw)
    UNTIL h = 0
  ELSIF mode = Display.paint THEN
    REPEAT
      CopyBLine1(dx, src, dst, w);
      DEC(h);  INC(src, bw);  INC(dst, dbw)
    UNTIL h = 0
  ELSIF mode = Display.replace THEN
    REPEAT
      ReplBLine0(Display.white, dx, dst, w); (*clear*)
      CopyBLine1(dx, src, dst, w);                  (*paint*)
      (*CopyBLine0(dx, src, dst, w);*)            (*clear & paint*)
      DEC(h);  INC(src, bw);  INC(dst, dbw)
    UNTIL h = 0
  END

END DisplayBlock;

PROCEDURE GetPix*(VAR addr: INTEGER; VAR buf: BYTE; depth: INTEGER);
  VAR s1, s2, s3: INTEGER;
BEGIN s1 := 0; s2 := 0;
  WHILE s1 < 8 DO SYSTEM.GET(addr, s3); INC(addr); INC(s1); s2 := s2*2 + s3 MOD 2 END; buf := s2
END GetPix;

PROCEDURE PutPix*(VAR addr, border: INTEGER; buf: BYTE; depth: INTEGER);
  VAR s1: INTEGER;
BEGIN s1 := 0;
  WHILE s1 < 8 DO
    IF addr < border THEN
      IF ODD(buf) THEN SYSTEM.PUT(addr, 15) ELSE SYSTEM.PUT(addr, 0) END
    END;
    INC(s1); INC(addr); buf := buf DIV 2;
  END
END PutPix;

PROCEDURE Copy*(sB, dB: Bitmap; sx, sy, w, h, dx, dy, mode: INTEGER);
BEGIN CopyBlock(sB, dB, sx, sy, w, h, dx, dy, mode)
END Copy;

PROCEDURE PutLine*(B: Bitmap; VAR data: ARRAY OF INTEGER; x, y, w: INTEGER);
  VAR dst, src, i: INTEGER; bt: BYTE;
BEGIN
  src := SYSTEM.ADR(data[0]); dst := B.base + y*B.width + x; i := w;
  WHILE i > 0 DO
    SYSTEM.GET(src, bt); SYSTEM.PUT(dst, bt);
    INC(src, 2); INC(dst);
    DEC(i)
  END
END PutLine;

PROCEDURE GetLine*(B: Bitmap; VAR data: ARRAY OF INTEGER; x, y, w: INTEGER);
  VAR dst, src, i: INTEGER; bt: BYTE;
BEGIN
  dst := SYSTEM.ADR(data[0]); src := B.base + y*B.width + x; i := w;
  WHILE i > 0 DO
    SYSTEM.GET(src, bt); SYSTEM.PUT(dst, bt);
    INC(src); INC(dst, 2);
    DEC(i)
  END
END GetLine;

BEGIN Texts.OpenWriter(W)
END Bitmaps.
