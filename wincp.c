#include "hbapi.h"
#include "hbapiitm.h"
#include <windows.h>

HB_FUNC( SETCONSOLECP862 )
{
   SetConsoleCP( 862 );
   SetConsoleOutputCP( 862 );
}

/* Build a 256-char Unicode translation string for CP862 (DOS Hebrew).
   GTWIN uses this via HB_GTI_UNITRANS to map byte values to Unicode
   codepoints when outputting to the console. */
HB_FUNC( BUILDCP862TRANS )
{
   wchar_t trans[ 256 ];
   int i;

   /* 0x00-0x7F: ASCII, same as Unicode */
   for( i = 0; i < 128; i++ )
      trans[ i ] = ( wchar_t ) i;

   /* 0x80-0x9A: Hebrew letters Alef(U+05D0) through Tav(U+05EA) = 27 chars */
   for( i = 0; i < 27; i++ )
      trans[ 0x80 + i ] = ( wchar_t )( 0x05D0 + i );

   /* 0x9B-0x9F: currency/special */
   trans[ 0x9B ] = 0x00A2; /* cent */
   trans[ 0x9C ] = 0x00A3; /* pound */
   trans[ 0x9D ] = 0x00A5; /* yen */
   trans[ 0x9E ] = 0x20A7; /* peseta */
   trans[ 0x9F ] = 0x0192; /* florin */

   /* 0xA0-0xA9: accented letters */
   trans[ 0xA0 ] = 0x00E1; /* a acute */
   trans[ 0xA1 ] = 0x00ED; /* i acute */
   trans[ 0xA2 ] = 0x00F3; /* o acute */
   trans[ 0xA3 ] = 0x00FA; /* u acute */
   trans[ 0xA4 ] = 0x00F1; /* n tilde */
   trans[ 0xA5 ] = 0x00D1; /* N tilde */
   trans[ 0xA6 ] = 0x00AA; /* fem ordinal */
   trans[ 0xA7 ] = 0x00BA; /* masc ordinal */
   trans[ 0xA8 ] = 0x00BF; /* inverted ? */
   trans[ 0xA9 ] = 0x2310; /* reversed not */

   /* 0xAA-0xAF: misc */
   trans[ 0xAA ] = 0x00AC; /* not sign */
   trans[ 0xAB ] = 0x00BD; /* 1/2 */
   trans[ 0xAC ] = 0x00BC; /* 1/4 */
   trans[ 0xAD ] = 0x00A1; /* inverted ! */
   trans[ 0xAE ] = 0x00AB; /* left guillemet */
   trans[ 0xAF ] = 0x00BB; /* right guillemet */

   /* 0xB0-0xDF: box drawing characters (same as cp437) */
   trans[ 0xB0 ] = 0x2591; /* light shade */
   trans[ 0xB1 ] = 0x2592; /* medium shade */
   trans[ 0xB2 ] = 0x2593; /* dark shade */
   trans[ 0xB3 ] = 0x2502; /* box vert */
   trans[ 0xB4 ] = 0x2524;
   trans[ 0xB5 ] = 0x2561;
   trans[ 0xB6 ] = 0x2562;
   trans[ 0xB7 ] = 0x2556;
   trans[ 0xB8 ] = 0x2555;
   trans[ 0xB9 ] = 0x2563;
   trans[ 0xBA ] = 0x2551; /* box double vert */
   trans[ 0xBB ] = 0x2557;
   trans[ 0xBC ] = 0x255D;
   trans[ 0xBD ] = 0x255C;
   trans[ 0xBE ] = 0x255B;
   trans[ 0xBF ] = 0x2510;
   trans[ 0xC0 ] = 0x2514;
   trans[ 0xC1 ] = 0x2534;
   trans[ 0xC2 ] = 0x252C;
   trans[ 0xC3 ] = 0x251C;
   trans[ 0xC4 ] = 0x2500; /* box horiz */
   trans[ 0xC5 ] = 0x253C;
   trans[ 0xC6 ] = 0x255E;
   trans[ 0xC7 ] = 0x255F;
   trans[ 0xC8 ] = 0x255A;
   trans[ 0xC9 ] = 0x2554;
   trans[ 0xCA ] = 0x2569;
   trans[ 0xCB ] = 0x2566;
   trans[ 0xCC ] = 0x2560;
   trans[ 0xCD ] = 0x2550; /* box double horiz */
   trans[ 0xCE ] = 0x256C;
   trans[ 0xCF ] = 0x2567;
   trans[ 0xD0 ] = 0x2568;
   trans[ 0xD1 ] = 0x2564;
   trans[ 0xD2 ] = 0x2565;
   trans[ 0xD3 ] = 0x2559;
   trans[ 0xD4 ] = 0x2558;
   trans[ 0xD5 ] = 0x2552;
   trans[ 0xD6 ] = 0x2553;
   trans[ 0xD7 ] = 0x256B;
   trans[ 0xD8 ] = 0x256A;
   trans[ 0xD9 ] = 0x2518;
   trans[ 0xDA ] = 0x250C;
   trans[ 0xDB ] = 0x2588; /* full block */
   trans[ 0xDC ] = 0x2584;
   trans[ 0xDD ] = 0x258C;
   trans[ 0xDE ] = 0x2590;
   trans[ 0xDF ] = 0x2580;

   /* 0xE0-0xEF: Greek/math symbols */
   trans[ 0xE0 ] = 0x03B1; /* alpha */
   trans[ 0xE1 ] = 0x00DF; /* sharp s */
   trans[ 0xE2 ] = 0x0393; /* Gamma */
   trans[ 0xE3 ] = 0x03C0; /* pi */
   trans[ 0xE4 ] = 0x03A3; /* Sigma */
   trans[ 0xE5 ] = 0x03C3; /* sigma */
   trans[ 0xE6 ] = 0x00B5; /* micro */
   trans[ 0xE7 ] = 0x03C4; /* tau */
   trans[ 0xE8 ] = 0x03A6; /* Phi */
   trans[ 0xE9 ] = 0x0398; /* Theta */
   trans[ 0xEA ] = 0x03A9; /* Omega */
   trans[ 0xEB ] = 0x03B4; /* delta */
   trans[ 0xEC ] = 0x221E; /* infinity */
   trans[ 0xED ] = 0x03C6; /* phi */
   trans[ 0xEE ] = 0x03B5; /* epsilon */
   trans[ 0xEF ] = 0x2229; /* intersection */

   /* 0xF0-0xFF: math/misc */
   trans[ 0xF0 ] = 0x2261; /* identical */
   trans[ 0xF1 ] = 0x00B1; /* plus-minus */
   trans[ 0xF2 ] = 0x2265; /* >= */
   trans[ 0xF3 ] = 0x2264; /* <= */
   trans[ 0xF4 ] = 0x2320; /* integral top */
   trans[ 0xF5 ] = 0x2321; /* integral bottom */
   trans[ 0xF6 ] = 0x00F7; /* division */
   trans[ 0xF7 ] = 0x2248; /* approx */
   trans[ 0xF8 ] = 0x00B0; /* degree */
   trans[ 0xF9 ] = 0x2219; /* bullet op */
   trans[ 0xFA ] = 0x00B7; /* middle dot */
   trans[ 0xFB ] = 0x221A; /* sqrt */
   trans[ 0xFC ] = 0x207F; /* superscript n */
   trans[ 0xFD ] = 0x00B2; /* superscript 2 */
   trans[ 0xFE ] = 0x25A0; /* black square */
   trans[ 0xFF ] = 0x00A0; /* nbsp */

   /* Return as Harbour string (raw bytes, 256 * sizeof(wchar_t)) */
   hb_retclen( ( const char * ) trans, 256 * sizeof( wchar_t ) );
}
