MODULE BitsTest; (*TK 16.9.2017*)
  IMPORT Bitmaps, Display, Texts, Oberon;
  VAR W: Texts.Writer; Ba, Bb: Bitmaps.Bitmap; 

 PROCEDURE New*;
   VAR w, h: INTEGER; S: Texts.Scanner;
 BEGIN
   Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
   IF S.class = Texts.Int THEN
     w := S.i; Texts.Scan(S);
     IF S.class = Texts.Int THEN h := S.i END
   END;
   
   Ba := Bitmaps.New(w, h, 1); Bb := Bitmaps.New(w, h, 1);
 END New;

 PROCEDURE DisplayBits*;
   VAR x, y, mode: INTEGER; S: Texts.Scanner;
 BEGIN
   Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
   IF S.class = Texts.Int THEN x := S.i; Texts.Scan(S);
     IF S.class = Texts.Int THEN y := S.i; Texts.Scan(S);
       IF S.class = Texts.Int THEN mode := S.i END
     END
   END;
   
   IF (Ba # NIL) & (Bb # NIL) THEN

        (* simple bitmap copy *)
        Bitmaps.Clear(Ba);
        Bitmaps.DisplayBlock(Ba, 0, 0, Ba.width, Ba.height, x, y, mode);
        Bitmaps.Copy(Ba, Bb, 0, 0, Ba.width, Ba.height, 0, 0, mode);
        Bitmaps.DisplayBlock(Bb, 0, 0, Bb.width, Bb.height, x+70, y, mode);
    
        (* bitmap & pattern copy *)
        Bitmaps.Clear(Ba);
        Bitmaps.CopyPattern(Ba, Display.black, Display.arrow, Ba.width DIV 2, Ba.height DIV 2, mode);
        Bitmaps.DisplayBlock(Ba, 0, 0, Ba.width, Ba.height, x, y+70, mode);
        Bitmaps.CopyBlock(Ba, Bb, 0, 0, Ba.width, Ba.height, 0, 0, mode);
        Bitmaps.DisplayBlock(Bb, 0, 0, Bb.width, Bb.height, x+70, y+70, mode);

        (* bitmap & replicate copy *)
        Bitmaps.Clear(Ba);
        Bitmaps.ReplPattern(Ba, 0, Display.block, 2, 2, 8, 8, mode);
        Bitmaps.DisplayBlock(Ba, 0, 0, Ba.width, Ba.height, x, y+140, mode);
        Bitmaps.CopyBlock(Ba, Bb, 4, 4, 16, 16, 5, 10, mode);
        Bitmaps.DisplayBlock(Bb, 0, 0, Bb.width, Bb.height, x+70, y+140, mode);
  
        (* bitmap & pattern & replicate constant copy *)
        Bitmaps.Clear(Ba);
        Bitmaps.CopyPattern(Ba, Display.black, Display.block, 2, 2, mode);
        Bitmaps.DisplayBlock(Ba, 0, 0, Ba.width, Ba.height, x, y+210, mode);
        Bitmaps.ReplConst(Ba, Display.white, 12, 10, 15, 20, mode);
        Bitmaps.DisplayBlock(Ba, 0, 0, Ba.width, Ba.height, x+70, y+210, mode);
  
        (* bitmap & dot *)
        Bitmaps.Clear(Ba);
        Bitmaps.Dot(Ba, Display.black, x, y, mode);
        Bitmaps.DisplayBlock(Ba, 0, 0, Ba.width, Ba.height, x, y+280, mode);

   END;

   (* Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)*)
 END DisplayBits;

BEGIN Texts.OpenWriter(W)
END BitsTest.
