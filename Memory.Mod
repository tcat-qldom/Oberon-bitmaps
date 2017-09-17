MODULE Memory; (*New(ptr, size) for Original Oberon 2013 / AP 13.4.16*)
  IMPORT SYSTEM, Kernel, Modules;
  CONST DescSize = 56; (*type descriptor*)
    DescHeapSize = 64; (*type descriptor plus fields tag and mark*)
    offset = 52; (*offset of field "next" in type descriptor*)

  TYPE Pointer* = POINTER TO RECORD END ;
    Tag = POINTER TO TypeDesc;
    TypeDesc = RECORD
      size: LONGINT; (*size of heap record including hidden fields tag and mark*)
      ext: ARRAY 3 OF LONGINT; (*extension table containing tags of base types*)
      ptr: ARRAY 8 OF LONGINT; (*pointer field offsets*)
      mark: LONGINT;
      next: Tag
    END ;

  VAR root: Tag; (*list of type descriptors created by procedure New1*)
    td: TypeDesc; (*used as type descriptor for list members*)

  PROCEDURE New*(VAR ptr: Pointer; size: LONGINT);
    VAR t: Tag;
  BEGIN (*convert size for heap allocation*)
    IF size <= 24 THEN size := 32 ELSIF size <= 56 THEN size := 64 ELSIF size <= 120 THEN size := 128
    ELSE size := (size+263) DIV 256 * 256
    END ;
    t := root;
    WHILE (t # NIL) & (t.size # size) DO t := t.next END ;
    IF t = NIL THEN (*allocate type descriptor*) Kernel.New(SYSTEM.VAL(LONGINT, t), SYSTEM.ADR(td));
      t.next := root; root := t; t.mark := 0; t.size := size;
      t.ext[0] := -1; t.ext[1] := -1; t.ext[2] := -1; t.ptr[0] := -1
    END ;
    IF t = NIL THEN ptr := NIL ELSE Kernel.New(SYSTEM.VAL(LONGINT, ptr), SYSTEM.ADR(t)) END
  END New;

  PROCEDURE CollectTD;
    VAR t, prev: Tag;
      p, mark, tag, size: LONGINT; continue: BOOLEAN;
  BEGIN p := Kernel.heapOrg;
    REPEAT SYSTEM.GET(p+4, mark);
      IF mark < 0 THEN (*free*) SYSTEM.GET(p, size)
      ELSE (*allocated*) SYSTEM.GET(p, tag); SYSTEM.GET(tag, size);
        IF mark > 0 THEN (*marked*) SYSTEM.PUT(p+4, 0); t := root; continue := TRUE;
          WHILE continue & (t # NIL) DO
            IF SYSTEM.VAL(LONGINT, t) = tag THEN INC(t.mark); continue := FALSE END ;
            t := t.next
          END
        END
      END ;
      INC(p, size)
    UNTIL p >= Kernel.heapLim;
    t := root;
    WHILE t # NIL DO
      IF t.mark > 0 THEN t.mark := 0; prev := t
      ELSIF t = root THEN root := root.next
      ELSE prev.next := t.next
      END ;
      t := t.next
    END
  END CollectTD;

  PROCEDURE Collect*; (*no longer referenced type descriptors created by New*)
    VAR mod: Modules.Module;
  BEGIN
    IF root # NIL THEN mod := Modules.root;
      WHILE mod # NIL DO
        IF mod.name[0] # 0X THEN Kernel.Mark(mod.ptr) END ;
        mod := mod.next
      END ;
      CollectTD
    END
  END Collect;

  PROCEDURE InitTD;
  BEGIN root := NIL; td.size := DescHeapSize;
    td.ext[0] := -1; td.ext[1] := -1; td.ext[2] := -1;
    td.ptr[0] := offset; (*field "next"*) td.ptr[1] := -1
  END InitTD;

BEGIN InitTD
END Memory.
