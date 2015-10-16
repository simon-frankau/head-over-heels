/***
 * Z80 Disassembler
 *
 * This little Disassembler Z80 code was created in an afternoon.
 * There is no user interface! Size of disassemblierenden ROMs and
 * Any more jumps change directly in the source code!
 *
 * It can be translated under Think C 5.0 on the Macintosh. Who does not
 * Macintosh has, on the one must convert the umlauts in the source code, and
 * - If you have no C + + compiler - change the comments of \ \.
 *
 * In addition, an ANSI library (file functions) is required. But also the
 * You can easily switch (see main ()). This is always the file "EPROM"
 * Loaded. Can be changed, of course ...
 *
 * The program consists of two parts:
 * 1 Analysis of the program. Here, the program is different from the
 * Hardware-vectors of the Z80 (RST commands, NMI) are processed and all Spünge
 * Performed by a recursive subroutine (ParseOpcodes). Here are
 * Found opcodes in an array (OpcodesFlags) marked. Also addresses
 * Be used as the target are marked there. The disassembler
 * Later can therefore see exactly whether he has data or program code itself!
 * There are exceptions, of course, can not detect it:
 * A) self-modifying code. Something should be in a ROM normally
 * Not occur.
 * B) calculated jumps with JP (IY), JP (IX) or JP (HL). Again,
 * The parser does not recognize the jumps. One lands in MacsBug when
 * Such a jump is found. Who sets the symbol DEBUGGER to 0
 * Have peace ...
 * C) jump tables. These occur unfortunately quite common. Only solution:
 * See program and disassemble. If you jump the tables
 * Has been found, you can - as with my Futura aquarium computer ROMs
 * Happen - more ParseOpcodes () insert calls. How and where the
 * Goes, stands in main ()
 * D) Non-user code. The code will never be skipped, of course, by
 * The analysis is not found. It mostly has to such a code not
 * Shame :-) Often the "unused" code will be a jump table
 * Jumped! So beware!
 * 2 Disassemble the program. With the help of the generated when parsing
 * OpcodesFlags table is now created a listing. Disassemble the subroutine
 * Is unfortunately quite "elongated". It disassembles an opcode from an address
 * In ROM in a buffer. I have it written down in one piece (at Hand
 * A Opcodeliste). In particular, the administration of IX and IY can be safely
 * Greatly reduce ...
 *
 * The subroutine OpcodeLen () returns the length of an opcode in bytes. It
 * Is required during parsing and during Disassemblierens.
 *
 * The disassembler knows the way _not_ hidden opcodes of the Z80. I had
 * No table above. In my case that were not even necessary ... Anyone who is
 * A list can have, the disassembler supplement a try.
 *
 * Incidentally, if a subroutine expects an "address" in the Z80 code, then
 * So a _Offset_ the array meant by the code! Pointers are NOT!
 * Longs are moreover unnecessary, for a Z80 has only 64K yes ...
 *
 * In main () you can rather than a disassembly with labels with a
 * Address and hexdump set before the opcode. Very handy for any errors
 * To find the disassembler or creating a list of variables.
 *
 *
 * This program is freeware. It should _not_ a basis for a commercial
 * Product will be taken! I assume no liability for damages incurred directly
 * Or indirectly arising from the use of this program!
 *
 * Anyone who wants to contact me can do so at the best company in our mailbox:
 *
 * Sigma Soft-Mailbox
 * © 1992 Σ-Soft, Markus Fritze
 ***/


/***
 *  Z80 Disassembler
 *
 *  Dieser kleine Disassembler für Z80-Code ist an einem Nachmittag entstanden.
 *  Es gibt keine Benutzeroberfläche! Größe des zu disassemblierenden ROMs und
 *  eventuelle weitere Sprünge sind direkt im Programmcode zu ändern!!!
 *
 *  Er läßt sich unter Think C 5.0 auf dem Macintosh übersetzen. Wer keinen
 *  Macintosh hat, darf zum einen die Umlaute im Sourcecode wandeln, und
 *  — sofern man keinen C++ Compiler hat — die Kommentare von \\ umstellen.
 *
 *  Ferner wird eine ANSI-Library (Dateifunktionen) benötigt. Aber auch das
 *  kann man leicht umstellen (siehe main()). Hier wird stets die Datei “EPROM”
 *  geladen. Kann man natürlich ändern…
 *
 *  Das Programm besteht aus zwei Teilen:
 *  1.  Analyse des Programms. Hierbei wird das Programm ab den verschiedenen
 *      Hardware-Vektoren des Z80 (RST-Befehle, NMI) durchgegangen und alle Spünge
 *      durch ein rekursives Unterprogramm (ParseOpcodes) ausgeführt. Dabei werden
 *      gefundene Opcodes in einem Array (OpcodesFlags) markiert. Auch Adressen, die
 *      als Sprungziele verwendet werden, sind dort markiert. Der Disassembler
 *      kann später also genau erkennen, ob er Daten oder Programmcode vor sich hat!
 *      Dabei gibt es natürlich Ausnahmen, die er nicht erkennen kann:
 *      a)  selbstmodifizierender Code. Sowas sollte in einem ROM normalerweise
 *          nicht auftreten.
 *      b)  berechnete Sprünge mit JP (IY), JP (IX) oder JP (HL). Auch hier kann
 *          der Parser die Sprünge nicht erkennen. Man landet im MacsBug, wenn
 *          so ein Sprung gefunden wurde. Wer das Symbol DEBUGGER auf 0 setzt,
 *          hat Ruhe…
 *      c)  Sprungtabellen. Diese treten leider recht häufig auf. Einzige Lösung:
 *          Programm disassemblieren und ansehen. Wenn man die Sprungtabellen
 *          gefunden hat, kann man — wie bei meinem Futura Aquariencomputer ROMs
 *          geschehen — weitere ParseOpcodes() Aufrufe einfügen. Wie und wo das
 *          geht, steht in main()
 *      d)  Unbenutzer Code. Code der nie angesprungen wird, wird natürlich durch
 *          die Analyse nicht gefunden. I.d.R. ist es um solchen Code auch nicht
 *          schade :-) Häufig wird der "unbenutzte" Code jedoch über eine Sprungtabelle
 *          angesprungen! Also Achtung!
 *  2.  Disassemblieren des Programms. Mit Hilfe der beim Parsen erzeugten
 *      OpcodesFlags-Tabelle wird nun ein Listing erzeugt. Das Disassemble-Unterprogramm
 *      ist leider recht "länglich". Es disassembliert einen Opcode ab einer Adresse
 *      im ROM in einen Buffer. Ich habe es in einem Stück runtergeschrieben (an Hand
 *      einer Opcodeliste). Inbesondere die Verwaltung von IX und IY kann man sicher
 *      stark kürzen…
 *
 *  Das Unterprogramm OpcodeLen() ermittelt die Länge eines Opcodes in Bytes. Es
 *  wird während des Parsens und während des Disassemblierens benötigt.
 *
 *  Der Disassembler kennt übrigens _keine_ versteckten Opcodes des Z80. Ich hatte
 *  keine Tabelle darüber. In meinem Fall waren die auch gar nicht nötig… Wer so
 *  eine Liste hat, kann den Disassembler ja mal ergänzen.
 *
 *  Wenn übrigens ein Unterprogramm eine "Adresse" im Z80-Code erwartet, so ist
 *  damit ein _Offset_ auf das Array mit dem Code gemeint! Pointer sind es NICHT!
 *  Longs sind übrigens unnötig, denn ein Z80 hat ja nur 64K…
 *
 *  In main() kann man anstatt einer Disassemblierung mit Labeln auch eine mit
 *  Adresse und Hexdump vor dem Opcode einstellen. Sehr praktisch um evtl. Fehler
 *  im Disassembler zu finden oder beim Erstellen einer Variablenliste.
 *
 *
 *  Das Programm ist Freeware. Es darf _nicht_ als Basis für ein kommerzielles
 *  Produkt genommen werden! Ich übernehme keine Haftung für Schäden, die direkt
 *  oder indirekt durch die Benutzung dieses Programms entstehen!
 *
 *  Wer mich erreichen will, kann dies am besten in unserer Firmen-Mailbox:
 *
 *  Sigma-Soft-Mailbox
 *  ©1992 ∑-Soft, Markus Fritze
 ***/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// #include <portab.h>
typedef void VOID;
typedef char *STR;
typedef char CHAR;
typedef char BYTE;
typedef unsigned char UBYTE;
typedef int WORD;
typedef unsigned int UWORD;
typedef int LONG;
typedef unsigned int ULONG;
typedef char Boolean;
const char xtrue = 1;
const char xfalse = 0;

#define CODESIZE        65535           // 64K Programmcode
#define FUTURA_189      0               // Sprungtabellen-Sprünge für Futura Aquariencomputer ROM V1.89
#define DEBUGGER        0               // wenn 1, dann landet man bei berechneten
                                        // Sprüngen im Debugger. Siehe auch oben.

// Speicher für den Programmcode
UBYTE       Opcodes[CODESIZE];

// Flag pro Speicherstelle, ob Opcode, Operand, Daten
// Bit 4 = 1, d.h. hier wird per JR o.ä. hingesprungen.
enum {
    Opcode,
    Operand,
    Data
} DataType;

UBYTE       OpcodesFlags[CODESIZE];

// Länge eines Opcodes in Bytes ermitteln
UBYTE       OpcodeLen(ULONG p)
{
UBYTE   len = 1;

    switch(Opcodes[p]) {// Opcode
    case 0x06:          // LD B,n
    case 0x0E:          // LD C,n
    case 0x10:          // DJNZ e
    case 0x16:          // LD D,n
    case 0x18:          // JR e
    case 0x1E:          // LD E,n
    case 0x20:          // JR NZ,e
    case 0x26:          // LD H,n
    case 0x28:          // JR Z,e
    case 0x2E:          // LD L,n
    case 0x30:          // JR NC,e
    case 0x36:          // LD (HL),n
    case 0x38:          // JR C,e
    case 0x3E:          // LD A,n
    case 0xC6:          // ADD A,n
    case 0xCE:          // ADC A,n
    case 0xD3:          // OUT (n),A
    case 0xD6:          // SUB n
    case 0xDB:          // IN A,(n)
    case 0xDE:          // SBC A,n
    case 0xE6:          // AND n
    case 0xEE:          // XOR n
    case 0xF6:          // OR n
    case 0xFE:          // CP n

    case 0xCB:          // Shift-,Rotate-,Bit-Befehle
                len = 2;
                break;
    case 0x01:          // LD BC,nn'
    case 0x11:          // LD DE,nn'
    case 0x21:          // LD HL,nn'
    case 0x22:          // LD (nn'),HL
    case 0x2A:          // LD HL,(nn')
    case 0x31:          // LD SP,(nn')
    case 0x32:          // LD (nn'),A
    case 0x3A:          // LD A,(nn')
    case 0xC2:          // JP NZ,nn'
    case 0xC3:          // JP nn'
    case 0xC4:          // CALL NZ,nn'
    case 0xCA:          // JP Z,nn'
    case 0xCC:          // CALL Z,nn'
    case 0xCD:          // CALL nn'
    case 0xD2:          // JP NC,nn'
    case 0xD4:          // CALL NC,nn'
    case 0xDA:          // JP C,nn'
    case 0xDC:          // CALL C,nn'
    case 0xE2:          // JP PO,nn'
    case 0xE4:          // CALL PO,nn'
    case 0xEA:          // JP PE,nn'
    case 0xEC:          // CALL PE,nn'
    case 0xF2:          // JP P,nn'
    case 0xF4:          // CALL P,nn'
    case 0xFA:          // JP M,nn'
    case 0xFC:          // CALL M,nn'
                len = 3;
                break;
    case 0xDD:  len = 2;
                switch(Opcodes[p+1]) {// 2.Teil des Opcodes
                case 0x34:          // INC (IX+d)
                case 0x35:          // DEC (IX+d)
                case 0x46:          // LD B,(IX+d)
                case 0x4E:          // LD C,(IX+d)
                case 0x56:          // LD D,(IX+d)
                case 0x5E:          // LD E,(IX+d)
                case 0x66:          // LD H,(IX+d)
                case 0x6E:          // LD L,(IX+d)
                case 0x70:          // LD (IX+d),B
                case 0x71:          // LD (IX+d),C
                case 0x72:          // LD (IX+d),D
                case 0x73:          // LD (IX+d),E
                case 0x74:          // LD (IX+d),H
                case 0x75:          // LD (IX+d),L
                case 0x77:          // LD (IX+d),A
                case 0x7E:          // LD A,(IX+d)
                case 0x86:          // ADD A,(IX+d)
                case 0x8E:          // ADC A,(IX+d)
                case 0x96:          // SUB A,(IX+d)
                case 0x9E:          // SBC A,(IX+d)
                case 0xA6:          // AND (IX+d)
                case 0xAE:          // XOR (IX+d)
                case 0xB6:          // OR (IX+d)
                case 0xBE:          // CP (IX+d)
                            len = 3;
                            break;
                case 0x21:          // LD IX,nn'
                case 0x22:          // LD (nn'),IX
                case 0x2A:          // LD IX,(nn')
                case 0x36:          // LD (IX+d),n
                case 0xCB:          // Rotation (IX+d)
                            len = 4;
                            break;
                }
                break;
    case 0xED:  len = 2;
                switch(Opcodes[p+1]) {// 2.Teil des Opcodes
                case 0x43:          // LD (nn'),BC
                case 0x4B:          // LD BC,(nn')
                case 0x53:          // LD (nn'),DE
                case 0x5B:          // LD DE,(nn')
                case 0x73:          // LD (nn'),SP
                case 0x7B:          // LD SP,(nn')
                            len = 4;
                            break;
                }
                break;
    case 0xFD:  len = 2;
                switch(Opcodes[p+1]) {// 2.Teil des Opcodes
                case 0x34:          // INC (IY+d)
                case 0x35:          // DEC (IY+d)
                case 0x46:          // LD B,(IY+d)
                case 0x4E:          // LD C,(IY+d)
                case 0x56:          // LD D,(IY+d)
                case 0x5E:          // LD E,(IY+d)
                case 0x66:          // LD H,(IY+d)
                case 0x6E:          // LD L,(IY+d)
                case 0x70:          // LD (IY+d),B
                case 0x71:          // LD (IY+d),C
                case 0x72:          // LD (IY+d),D
                case 0x73:          // LD (IY+d),E
                case 0x74:          // LD (IY+d),H
                case 0x75:          // LD (IY+d),L
                case 0x77:          // LD (IY+d),A
                case 0x7E:          // LD A,(IY+d)
                case 0x86:          // ADD A,(IY+d)
                case 0x8E:          // ADC A,(IY+d)
                case 0x96:          // SUB A,(IY+d)
                case 0x9E:          // SBC A,(IY+d)
                case 0xA6:          // AND (IY+d)
                case 0xAE:          // XOR (IY+d)
                case 0xB6:          // OR (IY+d)
                case 0xBE:          // CP (IY+d)
                            len = 3;
                            break;
                case 0x21:          // LD IY,nn'
                case 0x22:          // LD (nn'),IY
                case 0x2A:          // LD IY,(nn')
                case 0x36:          // LD (IY+d),n
                case 0xCB:          // Rotation,Bitop (IY+d)
                            len = 4;
                            break;
                }
                break;
    }
    return(len);
}

void DebugStr(char const *str)
{
  puts(str);
}

#define ParseOpcodes(x) { if ((x & 0xffff) == 0x7043) printf("XXX %x", adr); ParseOpcodesX(x); }

void        ParseOpcodesX(ULONG adr)
{
WORD    i,len;
ULONG   next;
Boolean label = xtrue;

    do {
      adr &= 0xffff;
      if (adr == 0) return;
      printf("0x%04x\n", adr);

      if (adr < 0x5b00) {
            DebugStr("\tToo low?!?");
            return;
        }
      if (adr > 0xc052) {
            DebugStr("\tToo high?!?");
            return;
        }

        if(label)                       // ein Label setzen?
            OpcodesFlags[adr] |= 0x10;  // Label setzen
        if((OpcodesFlags[adr] & 0x0F) == Opcode) break; // Schleife erkannt!
        if((OpcodesFlags[adr] & 0x0F) == Operand) {
            DebugStr("\tIllegaler Sprung?!?");
            return;
        }
        len = OpcodeLen(adr);           // Länge vom Opcode ermitteln
        for(i=0;i<len;i++)
            OpcodesFlags[adr+i] = Operand;  // Opcode eintragen
        OpcodesFlags[adr] = Opcode;     // Start des Opcodes markieren
        if(label) {                     // ein Label setzen?
            OpcodesFlags[adr] |= 0x10;  // Label setzen
            label = xfalse;              // Label-Flag zurücksetzen
        }

        next = adr + len;               // Ptr auf den Folgeopcode
        switch(Opcodes[adr]) {          // Opcode holen
        case 0xCA:      // JP c,????
        case 0xC2:
        case 0xDA:
        case 0xD2:
        case 0xEA:
        case 0xE2:
        case 0xFA:
        case 0xF2:
                ParseOpcodes((Opcodes[adr+2]<<8) + Opcodes[adr+1]);
                break;
        case 0x28:      // JR c,??
        case 0x20:
        case 0x38:
        case 0x30:
                ParseOpcodes(adr + 2 + (BYTE)Opcodes[adr+1]);
                break;
        case 0xCC:      // CALL c,????
        case 0xC4:
        case 0xDC:
        case 0xD4:
        case 0xEC:
        case 0xE4:
        case 0xFC:
        case 0xF4:
                ParseOpcodes((Opcodes[adr+2]<<8) + Opcodes[adr+1]);
                break;
        case 0xC8:      // RET c
        case 0xC0:
        case 0xD8:
        case 0xD0:
        case 0xE8:
        case 0xE0:
        case 0xF8:
        case 0xF0:
                break;
        case 0xC7:      // RST 0
        case 0xCF:      // RST 8
        case 0xD7:      // RST 10
        case 0xDF:      // RST 18
        case 0xE7:      // RST 20
        case 0xEF:      // RST 28
        case 0xF7:      // RST 30
        case 0xFF:      // RST 38
                ParseOpcodes(Opcodes[adr] & 0x38);
                break;
        case 0x10:      // DJNZ ??
                ParseOpcodes(adr + 2 + (BYTE)Opcodes[adr+1]);
                break;
        case 0xC3:      // JP ????
                next = (Opcodes[adr+2]<<8) + Opcodes[adr+1];
                label = xtrue;
                break;
        case 0x18:      // JR ??
                next = adr + 2 + (BYTE)Opcodes[adr+1];
                label = xtrue;
                break;
        case 0xCD:      // CALL ????
                ParseOpcodes((Opcodes[adr+2]<<8) + Opcodes[adr+1]);
                break;
        case 0xC9:      // RET
                return;
        case 0xE9:
#if DEBUGGER
                DebugStr("\pJP (HL) gefunden"); // JP (HL)
#endif
                break;
        case 0xDD:
#if DEBUGGER
                if(Opcodes[adr+1] == 0xE9) {    // JP (IX)
                    DebugStr("\pJP (IX) gefunden");
                }
#endif
                break;
        case 0xFD:
#if DEBUGGER
                if(Opcodes[adr+1] == 0xE9) {    // JP (IY)
                    DebugStr("\pJP (IY) gefunden");
                }
#endif
                break;
        case 0xED:
                if(Opcodes[adr+1] == 0x4D) {    // RTI
                    return;
                } else if(Opcodes[adr+1] == 0x45) { // RETN
                    return;
                }
                break;
        }
        adr = next;
    } while(1);
}

#define ParseOpcodes(x) ParseOpcodesX(x)

// Disassemblieren
VOID        Disassemble(UWORD adr,STR s)
{
UBYTE           a = Opcodes[adr];
UBYTE           d = (a >> 3) & 7;
UBYTE           e = a & 7;
static STR      reg[8] = {"B","C","D","E","H","L","(HL)","A"};
static STR      dreg[4] = {"BC","DE","HL","SP"};
static STR      cond[8] = {"NZ","Z","NC","C","PO","PE","P","M"};
static STR      arith[8] = {"ADD\t\tA,","ADC\t\tA,","SUB\t\t","SBC\t\tA,","AND\t\t","XOR\t\t","OR\t\t","CP\t\t"};
CHAR            stemp[80];      // temp.String für sprintf()
CHAR            ireg[3];        // temp.Indexregister

    switch(a & 0xC0) {
    case 0x00:
        switch(e) {
        case 0x00:
            switch(d) {
            case 0x00:
                strcpy(s,"NOP");
                break;
            case 0x01:
                strcpy(s,"EX\t\tAF,AF'");
                break;
            case 0x02:
                strcpy(s,"DJNZ\t");
                sprintf(stemp,"$%4.4X",adr+2+(BYTE)Opcodes[adr+1]);strcat(s,stemp);
                break;
            case 0x03:
                strcpy(s,"JR\t\t");
                sprintf(stemp,"$%4.4X",adr+2+(BYTE)Opcodes[adr+1]);strcat(s,stemp);
                break;
            default:
                strcpy(s,"JR\t\t");
                strcat(s,cond[d & 3]);
                strcat(s,",");
                sprintf(stemp,"$%4.4X",adr+2+(BYTE)Opcodes[adr+1]);strcat(s,stemp);
                break;
            }
            break;
        case 0x01:
            if(a & 0x08) {
                strcpy(s,"ADD\t\tHL,");
                strcat(s,dreg[d >> 1]);
            } else {
                strcpy(s,"LD\t\t");
                strcat(s,dreg[d >> 1]);
                strcat(s,",");
                sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
            }
            break;
        case 0x02:
            switch(d) {
            case 0x00:
                strcpy(s,"LD\t\t(BC),A");
                break;
            case 0x01:
                strcpy(s,"LD\tA,(BC)");
                break;
            case 0x02:
                strcpy(s,"LD\t\t(DE),A");
                break;
            case 0x03:
                strcpy(s,"LD\t\tA,(DE)");
                break;
            case 0x04:
                strcpy(s,"LD\t\t(");
                sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                strcat(s,"),HL");
                break;
            case 0x05:
                strcpy(s,"LD\t\tHL,(");
                sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                strcat(s,")");
                break;
            case 0x06:
                strcpy(s,"LD\t\t(");
                sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                strcat(s,"),A");
                break;
            case 0x07:
                strcpy(s,"LD\t\tA,(");
                sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                strcat(s,")");
                break;
            }
            break;
        case 0x03:
            if(a & 0x08)
                strcpy(s,"DEC\t\t");
            else
                strcpy(s,"INC\t\t");
            strcat(s,dreg[d >> 1]);
            break;
        case 0x04:
            strcpy(s,"INC\t\t");
            strcat(s,reg[d]);
            break;
        case 0x05:
            strcpy(s,"DEC\t\t");
            strcat(s,reg[d]);
            break;
        case 0x06:              // LD   d,n
            strcpy(s,"LD\t\t");
            strcat(s,reg[d]);
            strcat(s,",");
            sprintf(stemp,"$%2.2X",Opcodes[adr+1]);strcat(s,stemp);
            break;
        case 0x07:
            {
            static STR str[8] = {"RLCA","RRCA","RLA","RRA","DAA","CPL","SCF","CCF"};
            strcpy(s,str[d]);
            }
            break;
        }
        break;
    case 0x40:                          // LD   d,s
        if(a == 0x76) {
            strcpy(s,"HALT");
        } else {
            strcpy(s,"LD\t\t");
            strcat(s,reg[d]);
            strcat(s,",");
            strcat(s,reg[e]);
        }
        break;
    case 0x80:
        strcpy(s,arith[d]);
        strcat(s,reg[e]);
        break;
    case 0xC0:
        switch(e) {
        case 0x00:
            strcpy(s,"RET\t\t");
            strcat(s,cond[d]);
            break;
        case 0x01:
            if(d & 1) {
                switch(d >> 1) {
                case 0x00:
                    strcpy(s,"RET");
                    break;
                case 0x01:
                    strcpy(s,"EXX");
                    break;
                case 0x02:
                    strcpy(s,"JP\t\t(HL)");
                    break;
                case 0x03:
                    strcpy(s,"LD\t\tSP,HL");
                    break;
                }
            } else {
                strcpy(s,"POP\t\t");
                if((d >> 1)==3)
                    strcat(s,"AF");
                else
                    strcat(s,dreg[d >> 1]);
            }
            break;
        case 0x02:
            strcpy(s,"JP\t\t");
            strcat(s,cond[d]);
            strcat(s,",");
            sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
            break;
        case 0x03:
            switch(d) {
            case 0x00:
                strcpy(s,"JP\t\t");
                sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                break;
            case 0x01:                  // 0xCB
                a = Opcodes[++adr];     // Erweiterungsopcode holen
                d = (a >> 3) & 7;
                e = a & 7;
                stemp[1] = 0;           // temp.String = 1 Zeichen
                switch(a & 0xC0) {
                case 0x00:
                    {
                    static STR str[8] = {"RLC","RRC","RL","RR","SLA","SRA","???","SRL"};
                    strcpy(s,str[d]);
                    }
                    strcat(s,"\t\t");
                    strcat(s,reg[e]);
                    break;
                case 0x40:
                    strcpy(s,"BIT\t\t");
                    stemp[0] = d+'0';strcat(s,stemp);
                    strcat(s,",");
                    strcat(s,reg[e]);
                    break;
                case 0x80:
                    strcpy(s,"RES\t\t");
                    stemp[0] = d+'0';strcat(s,stemp);
                    strcat(s,",");
                    strcat(s,reg[e]);
                    break;
                case 0xC0:
                    strcpy(s,"SET\t\t");
                    stemp[0] = d+'0';strcat(s,stemp);
                    strcat(s,",");
                    strcat(s,reg[e]);
                    break;
                }
                break;
            case 0x02:
                strcpy(s,"OUT\t\t(");
                sprintf(stemp,"$%2.2X",Opcodes[adr+1]);strcat(s,stemp);
                strcat(s,"),A");
                break;
            case 0x03:
                strcpy(s,"IN\t\tA,(");
                sprintf(stemp,"$%2.2X",Opcodes[adr+1]);strcat(s,stemp);
                strcat(s,")");
                break;
            case 0x04:
                strcpy(s,"EX\t\t(SP),HL");
                break;
            case 0x05:
                strcpy(s,"EX\t\tDE,HL");
                break;
            case 0x06:
                strcpy(s,"DI");
                break;
            case 0x07:
                strcpy(s,"EI");
                break;
            }
            break;
        case 0x04:
            strcpy(s,"CALL\t");
            strcat(s,cond[d]);
            strcat(s,",");
            sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
            break;
        case 0x05:
            if(d & 1) {
                switch(d >> 1) {
                case 0x00:
                    strcpy(s,"CALL\t");
                    sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                    break;
                case 0x02:              // 0xED
                    a = Opcodes[++adr]; // Erweiterungsopcode holen
                    d = (a >> 3) & 7;
                    e = a & 7;
                    switch(a & 0xC0) {
                    case 0x40:
                        switch(e) {
                        case 0x00:
                            strcpy(s,"IN\t\t");
                            strcat(s,reg[d]);
                            strcat(s,",(C)");
                            break;
                        case 0x01:
                            strcpy(s,"OUT\t\t(C),");
                            strcat(s,reg[d]);
                            break;
                        case 0x02:
                            if(d & 1)
                                strcpy(s,"ADC");
                            else
                                strcpy(s,"SBC");
                            strcat(s,"\t\tHL,");
                            strcat(s,dreg[d >> 1]);
                            break;
                        case 0x03:
                            if(d & 1) {
                                strcpy(s,"LD\t\t");
                                strcat(s,dreg[d >> 1]);
                                strcat(s,",(");
                                sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                                strcat(s,")");
                            } else {
                                strcpy(s,"LD\t\t(");
                                sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                                strcat(s,"),");
                                strcat(s,dreg[d >> 1]);
                            }
                            break;
                        case 0x04:
                            {
                            static STR str[8] = {"NEG","???","???","???","???","???","???","???"};
                            strcpy(s,str[d]);
                            }
                            break;
                        case 0x05:
                            {
                            static STR str[8] = {"RETN","RETI","???","???","???","???","???","???"};
                            strcpy(s,str[d]);
                            }
                            break;
                        case 0x06:
                            strcpy(s,"IM\t\t");
                            stemp[0] = d + '0' - 1; stemp[1] = 0;
                            strcat(s,stemp);
                            break;
                        case 0x07:
                            {
                            static STR str[8] = {"LD\t\tI,A","???","LD\t\tA,I","???","RRD","RLD","???","???"};
                            strcpy(s,str[d]);
                            }
                            break;
                        }
                        break;
                    case 0x80:
                        {
                        static STR str[32] = {"LDI","CPI","INI","OUTI","???","???","???","???",
                                              "LDD","CPD","IND","OUTD","???","???","???","???",
                                              "LDIR","CPIR","INIR","OTIR","???","???","???","???",
                                              "LDDR","CPDR","INDR","OTDR","???","???","???","???"};
                        strcpy(s,str[a & 0x1F]);
                        }
                        break;
                    }
                    break;
                default:                // 0x01 (0xDD) = IX, 0x03 (0xFD) = IY
                    strcpy(ireg,(a & 0x20)?"IY":"IX");
                    a = Opcodes[++adr]; // Erweiterungsopcode holen
                    switch(a) {
                    case 0x09:
                        strcpy(s,"ADD\t\t");
                        strcat(s,ireg);
                        strcat(s,",BC");
                        break;
                    case 0x19:
                        strcpy(s,"ADD\t\t");
                        strcat(s,ireg);
                        strcat(s,",DE");
                        break;
                    case 0x21:
                        strcpy(s,"LD\t\t");
                        strcat(s,ireg);
                        strcat(s,",");
                        sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                        break;
                    case 0x22:
                        strcpy(s,"LD\t\t(");
                        sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                        strcat(s,"),");
                        strcat(s,ireg);
                        break;
                    case 0x23:
                        strcpy(s,"INC\t\t");
                        strcat(s,ireg);
                        break;
                    case 0x29:
                        strcpy(s,"ADD\t\t");
                        strcat(s,ireg);
                        strcat(s,",");
                        strcat(s,ireg);
                        break;
                    case 0x2A:
                        strcpy(s,"LD\t\t");
                        strcat(s,ireg);
                        strcat(s,",(");
                        sprintf(stemp,"$%4.4X",Opcodes[adr+1]+(Opcodes[adr+2]<<8));strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0x2B:
                        strcpy(s,"DEC\t\t");
                        strcat(s,ireg);
                        break;
                    case 0x34:
                        strcpy(s,"INC\t\t(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0x35:
                        strcpy(s,"DEC\t\t(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
						strcat(s,")");
                        break;
                    case 0x36:
                        strcpy(s,"LD\t\t(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,"),");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+2]);strcat(s,stemp);
                        break;
                    case 0x39:
                        strcpy(s,"ADD\t\t");
                        strcat(s,ireg);
                        strcat(s,",SP");
                        break;
                    case 0x46:
                    case 0x4E:
                    case 0x56:
                    case 0x5E:
                    case 0x66:
                    case 0x6E:
                        strcpy(s,"LD\t\t");
                        strcat(s,reg[(a>>3)&7]);
                        strcat(s,",(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0x70:
                    case 0x71:
                    case 0x72:
                    case 0x73:
                    case 0x74:
                    case 0x75:
                    case 0x77:
                        strcpy(s,"LD\t\t(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,"),");
                        strcat(s,reg[a & 7]);
                        break;
                    case 0x7D:
                        strcpy(s,"LD\t\tA,");
                        strcat(s,ireg);
                        strcat(s,"L");
                        break;
					case 0x7E:
                        strcpy(s,"LD\t\tA,(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0x86:
                        strcpy(s,"ADD\t\tA,(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0x8E:
                        strcpy(s,"ADC\t\tA,(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0x96:
                        strcpy(s,"SUB\t\t(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0x9E:
                        strcpy(s,"SBC\t\tA,(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0xA6:
                        strcpy(s,"AND\t\tA,(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0xAE:
                        strcpy(s,"XOR\t\tA,(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0xB6:
                        strcpy(s,"OR\t\tA,(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0xBE:
                        strcpy(s,"CP\t\tA,(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    case 0xE1:
                        strcpy(s,"POP\t\t");
                        strcat(s,ireg);
                        break;
                    case 0xE3:
                        strcpy(s,"EX\t\t(SP),");
                        strcat(s,ireg);
                        break;
                    case 0xE5:
                        strcpy(s,"PUSH\t");
                        strcat(s,ireg);
                        break;
                    case 0xE9:
                        strcpy(s,"JP\t\t(");
                        strcat(s,ireg);
                        strcat(s,")");
                        break;
                    case 0xF9:
                        strcpy(s,"LD\t\tSP,");
                        strcat(s,ireg);
                        break;
                    case 0xCB:
                        a = Opcodes[adr+2]; // weiteren Unteropcode
                        d = (a >> 3) & 7;
                        stemp[1] = 0;
                        switch(a & 0xC0) {
                        case 0x00:
                            {
                            static STR str[8] = {"RLC","RRC","RL","RR","SLA","SRA","???","SRL"};
                            strcpy(s,str[d]);
                            }
                            strcat(s,"\t\t");
                            break;
                        case 0x40:
                            strcpy(s,"BIT\t\t");
                            stemp[0] = d + '0';
                            strcat(s,stemp);
                            strcat(s,",");
                            break;
                        case 0x80:
                            strcpy(s,"RES\t\t");
                            stemp[0] = d + '0';
                            strcat(s,stemp);
                            strcat(s,",");
                            break;
                        case 0xC0:
                            strcpy(s,"SET\t\t");
                            stemp[0] = d + '0';
                            strcat(s,stemp);
                            strcat(s,",");
                            break;
                        }
                        strcat(s,"(");
                        strcat(s,ireg);
                        strcat(s,Opcodes[adr+1] >= 0x80 ? "-" : "+");
                        sprintf(stemp,"$%2.2X",Opcodes[adr+1] >= 0x80 ? 0x100-((int)Opcodes[adr+1]) : Opcodes[adr+1]);strcat(s,stemp);
                        strcat(s,")");
                        break;
                    }
                    break;
                }
            } else {
                strcpy(s,"PUSH\t");
                if((d >> 1)==3)
                    strcat(s,"AF");
                else
                    strcat(s,dreg[d >> 1]);
            }
            break;
        case 0x06:
            strcpy(s,arith[d]);
            sprintf(stemp,"$%2.2X",Opcodes[adr+1]);strcat(s,stemp);
            break;
        case 0x07:
            strcpy(s,"RST\t\t");
            sprintf(stemp,"$%2.2X",a & 0x38);strcat(s,stemp);
            break;
        }
        break;
    }
}

// Einlesen, Parsen, Disassemblieren und Ausgeben
int        main(void)
{
WORD    i;
FILE    *f;
UWORD   adr = 0;
CHAR    s[80];          // Ausgabestring

//    f = fopen("memdump.bin","rb");
    f = fopen("memimage.bin","rb");
    if(!f) return 1;
    fread(Opcodes,CODESIZE,1,f);    // EPROM einlesen
    fclose(f);

    for(i=0;i<CODESIZE;i++)         // alles Daten…
        OpcodesFlags[i] = Data;

    ParseOpcodes(0x7030);
	ParseOpcodes(0x7169);
    ParseOpcodes(0x72EB);
	ParseOpcodes(0x72F3);
	ParseOpcodes(0x734B);
	ParseOpcodes(0x7376);
	ParseOpcodes(0x7564);
	ParseOpcodes(0x757D);
	ParseOpcodes(0x75A4);
	ParseOpcodes(0x7B78);
// 7EA3 looks like strings?
    ParseOpcodes(0x880A);
	ParseOpcodes(0x8835);
	ParseOpcodes(0x8844);
	ParseOpcodes(0x884D);
	ParseOpcodes(0x885D);
	ParseOpcodes(0x8895);
	ParseOpcodes(0x88A6);
	ParseOpcodes(0x8CFF);
	ParseOpcodes(0x8EAC);
	ParseOpcodes(0x8EDB);
	ParseOpcodes(0x8EEB);
	ParseOpcodes(0x8F08);
	ParseOpcodes(0x8F18);
	ParseOpcodes(0x8F2E);
	ParseOpcodes(0x8F4E);
	ParseOpcodes(0x8F66);
	ParseOpcodes(0x8F76);
	ParseOpcodes(0x8FB8);
	ParseOpcodes(0x8FC6);
	ParseOpcodes(0x901E);
	ParseOpcodes(0x902B);
	ParseOpcodes(0x9036);
	ParseOpcodes(0x903A);
	ParseOpcodes(0x903E);
	ParseOpcodes(0x9042);
	ParseOpcodes(0x904C);
	ParseOpcodes(0x9053);
	ParseOpcodes(0x9088);
	ParseOpcodes(0x90BF);
	ParseOpcodes(0x90D7);
	ParseOpcodes(0x90DD);
	ParseOpcodes(0x90E3);
	ParseOpcodes(0x90E8);
	ParseOpcodes(0x90ED);
	ParseOpcodes(0x90F2);
	ParseOpcodes(0x90F7);
	ParseOpcodes(0x90FC);
	ParseOpcodes(0x9101);
	ParseOpcodes(0x9106);
	ParseOpcodes(0x910B);
	ParseOpcodes(0x9171);
	ParseOpcodes(0x91E4);
	ParseOpcodes(0x91F1);
	ParseOpcodes(0x9200);
	ParseOpcodes(0x920D);
	ParseOpcodes(0x9214);
	ParseOpcodes(0x921F);
	ParseOpcodes(0x9226);
	ParseOpcodes(0x9245);
	ParseOpcodes(0x925D);
	ParseOpcodes(0x9264);
	ParseOpcodes(0x9442);
	ParseOpcodes(0x9462);
	ParseOpcodes(0x9484);
	ParseOpcodes(0x94A8);
	ParseOpcodes(0x94CB);
	ParseOpcodes(0x9A25);
	ParseOpcodes(0x9A3A);
	ParseOpcodes(0x9A79);
	ParseOpcodes(0x9A90);
	ParseOpcodes(0x9AAE);
	ParseOpcodes(0x9AD3);
	ParseOpcodes(0x9AFE);
	ParseOpcodes(0x9B17);
	ParseOpcodes(0x9B37);
	ParseOpcodes(0x9B5E);
	ParseOpcodes(0x9B8B);
	ParseOpcodes(0x9CF7);
	ParseOpcodes(0x9CFC);
	ParseOpcodes(0x9E07);
	ParseOpcodes(0x9E2C);
	ParseOpcodes(0x9E46);
	ParseOpcodes(0x9E73);
	ParseOpcodes(0x9E80);
	ParseOpcodes(0x9EA9);
	ParseOpcodes(0x9EAD);
	ParseOpcodes(0x9EBB);

	// 9F3A is a jump table for:
	ParseOpcodes(0x9F46);
	ParseOpcodes(0x9F6F);
	ParseOpcodes(0x9F98);
	ParseOpcodes(0x9FBB);
	ParseOpcodes(0x9FF3);
	ParseOpcodes(0xA02B);
	ParseOpcodes(0xB24B);
	// B378 looks like start of jump table.
	ParseOpcodes(0xB39F);
	ParseOpcodes(0xB3C0);
	ParseOpcodes(0xB3E4);
	ParseOpcodes(0xB407);
	ParseOpcodes(0xB428);
	ParseOpcodes(0xB469);
	ParseOpcodes(0xB484);
	ParseOpcodes(0xB4A2);
	ParseOpcodes(0xB4BE);
	ParseOpcodes(0xB515);
	ParseOpcodes(0xB565);
	ParseOpcodes(0xB5AD);
	ParseOpcodes(0xB715);
	ParseOpcodes(0xB71A);
	ParseOpcodes(0xB728);
	ParseOpcodes(0xB734);
	ParseOpcodes(0xB824);
	// ParseOpcodes(0xB82F);

ParseOpcodes(0xBA40);


// Data from 0xB824ish?

    /*
    for(i=0;i<0x5b00;i++)
        OpcodesFlags[i] = Data;
    for(i=0xbdaf;i<0xfac0;i++)
        OpcodesFlags[i] = Data;
    */

    f = stdout;
    f = fopen("memimage.asm","w");
    if(!f) return 2;
    while(adr < CODESIZE) {
        WORD    len,i;

        if((OpcodesFlags[adr] & 0x0F) == Data) {
            fprintf(f,"L%4.4X:\tDEFB",(UWORD)adr);
            for(i=0;i<16;i++) {
                if((OpcodesFlags[adr+i] & 0x0F) != Data) break;
                fprintf(f,"%c$%2.2X",(i)?',':' ',Opcodes[adr+i]);
            }
            fprintf(f,"\n");
            adr += i;
        } else {
            len = OpcodeLen(adr);           // Länge vom Opcode ermitteln
#if 1
            if(OpcodesFlags[adr] & 0x10)
                fprintf(f,"L%4.4X:\t",adr);
            else
                fprintf(f,"\t\t");
#else
            fprintf(f,"%4.4X: ",(UWORD)adr);
            for(i=0;i<len;i++)
                fprintf(f,"%2.2X ",Opcodes[adr+i]);
            for(i=4;i>len;i--)
                fprintf(f,"   ");
            fprintf(f," ");
#endif
            Disassemble(adr,s);
            fprintf(f,"%s\n",s);
            adr += len;
        }
    }
    fclose(f);
    return 0;
}
