#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wcmoapi.h"


#if defined(MS_WINNT)

#define CDI_PATH         "s:\\cmo_cdi"
#define CDU_PATH         "s:\\cmo_cdu"

#ifdef _WIN64
#define VCMOWRAP_LIBNAME ".\\vcmowr64.dll"
#else
#define VCMOWRAP_LIBNAME ".\\vcmowrap.dll"
#endif

#elif defined(LINUX)

#define CDI_PATH         "/home/database/data/source/cmo_cdi"
#define CDU_PATH         "/home/database/data/source/cmo_cdu"

#define VCMOWRAP_LIBNAME "./libvcmowrap.so"

#elif defined(SOLARIS)

#define CDI_PATH         "/mnt/fin/data/source/cmo_cdi"
#define CDU_PATH         "/mnt/fin/data/source/cmo_cdu"

#define VCMOWRAP_LIBNAME "./libvcmowrap.so"

#endif

/* Declare a structure to hold pointers to the exported VCMOWRAP functions we will be calling. */
VCMOWRAP_FCN Vcmowrap ;


/* VCMOWRAP_INIT_FCNS: Load the functions we're going to use in this application. */

static int vcmowrap_init_fcns( WCMOModule vcmowrapModule )
{
#define SetFcn( fcnname ) (Vcmowrap.fcnname = (FCN_##fcnname) WCMOLoadSymbol( vcmowrapModule, #fcnname ))

return ( SetFcn(wcmo_init)          == NULL ||
         SetFcn(wcmo_deal)          == NULL ||
         SetFcn(wcmo_exit)          == NULL ||

     /* The support functions for handling WCMOARGs */

         SetFcn(wcmoarg_alloc)      == NULL ||
         SetFcn(wcmoarg_set_string) == NULL ||
         SetFcn(wcmoarg_get_string) == NULL ||
         SetFcn(wcmoarg_free)       == NULL ) ;
}


/* FIND_TOKEN: A utility function to find the value associated with a given     */
/*     keyword string. This simple function serves for illustrative purposes,   */
/*     but in production code, particularly if extracting multiple keywords     */
/*     from a single output argument, it might be more efficient to pre-process */
/*     the output string into a data structure (such as a hash table keyed by   */
/*     the keyword) that allows for lookup in faster than O(n) time.            */

static char *find_token( WCMOARG *wcmoarg, char *string )
{
char   *cpos ;
size_t  len = strlen( string ) ;

if ( (cpos = Vcmowrap.wcmoarg_get_string( wcmoarg )) != NULL )
    {
    while( strncmp( cpos, string, len ) != 0 || cpos[len] != '=' )
        {
        cpos = strchr( cpos, 10 ) ;   /* the ASCII value chosen in wcmo_init() for record delimiters */
        if ( cpos != NULL )
            cpos++ ;
        if ( *cpos == '\0' )
            {
            cpos = NULL ;
            break ;
            }
        }
    if ( cpos != NULL )
        cpos += len+1 ;
    }

return cpos ;
}


int main( void )
{
WCMOModule  vcmowrapModule = NULL ;
int         retval         = EXIT_SUCCESS ;
int         initialized    = 0 ;
WCMOARG     Handle   = NULL, * const wcmoarg_Handle   = &Handle ;
WCMOARG     User     = NULL, * const wcmoarg_User     = &User ;
WCMOARG     Deal     = NULL, * const wcmoarg_Deal     = &Deal ;
WCMOARG     Options  = NULL, * const wcmoarg_Options  = &Options ;
WCMOARG     Cashflow = NULL, * const wcmoarg_Cashflow = &Cashflow ;
WCMOARG     Loanscen = NULL, * const wcmoarg_Loanscen = &Loanscen ;
WCMOARG     Propscen = NULL, * const wcmoarg_Propscen = &Propscen ;
WCMOARG     Stats    = NULL, * const wcmoarg_Stats    = &Stats ;
WCMOARG     Unused1  = NULL, * const wcmoarg_Unused1  = &Unused1 ;
WCMOARG     Unused2  = NULL, * const wcmoarg_Unused2  = &Unused2 ;
WCMOARG     DataOut  = NULL, * const wcmoarg_DataOut  = &DataOut ;
WCMOARG     ErrOut   = NULL, * const wcmoarg_ErrOut   = &ErrOut ;

if ( (vcmowrapModule = WCMOLoadModule( VCMOWRAP_LIBNAME )) == NULL )
    {
    fprintf( stderr, "Unable to load %s\n", VCMOWRAP_LIBNAME ) ;
    retval = EXIT_FAILURE ;
    goto DONE_ACTION ;
    }

if ( vcmowrap_init_fcns( vcmowrapModule ) )
    {
    fprintf( stderr, "Unable to load some function(s) from %s\n", VCMOWRAP_LIBNAME ) ;
    retval = EXIT_FAILURE ;
    goto DONE_ACTION ;
    }

/***********************************/
/*        Allocate WCMOARGs        */
/***********************************/

Vcmowrap.wcmoarg_alloc( wcmoarg_Handle  ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_User    ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_Deal    ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_Options ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_Cashflow ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_Loanscen ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_Propscen ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_Stats ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_Unused1 ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_Unused2 ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_DataOut ) ;
Vcmowrap.wcmoarg_alloc( wcmoarg_ErrOut  ) ;

/***********************************/
/* Initialize the Wrapper instance */
/***********************************/

Vcmowrap.wcmoarg_set_string( wcmoarg_Handle,
"KEYVAL_DELIM_ASCII=10\n"     /* Use '\n' (= char(10)), so argument strings will look good when printed to screen */
 ) ;

if ( Vcmowrap.wcmo_init( wcmoarg_Handle, wcmoarg_User, wcmoarg_DataOut, wcmoarg_ErrOut ) )
    {
    fprintf( stderr, "\n\nwcmo_init() ErrOut:\n%s\n", Vcmowrap.wcmoarg_get_string( wcmoarg_ErrOut ) ) ;
    retval = EXIT_FAILURE ;
    goto DONE_ACTION ;
    }
else
    printf( "\n\nwcmo_init() DataOut:\n%s\n", Vcmowrap.wcmoarg_get_string( wcmoarg_DataOut ) ) ;

initialized = 1 ;


/***********************************/
/*         Parse the deal          */
/***********************************/

Vcmowrap.wcmoarg_set_string( wcmoarg_Options,
"CDI_PATH=" CDI_PATH "\n"
"CDU_PATH=" CDU_PATH "\n"
) ;

Vcmowrap.wcmoarg_set_string( wcmoarg_Deal,
"DEAL_NAME=fhl034\n"
"DEAL_MODE=NEW\n"
) ;

if ( Vcmowrap.wcmo_deal( wcmoarg_Handle, wcmoarg_User, wcmoarg_Options, wcmoarg_Deal, wcmoarg_DataOut, wcmoarg_ErrOut ) )
    {
    fprintf( stderr, "\n\nwcmo_deal() ErrOut:\n%s\n", Vcmowrap.wcmoarg_get_string( wcmoarg_ErrOut ) ) ;
    retval = EXIT_FAILURE ;
    goto DONE_ACTION ;
    }
else
    printf( "\n\nwcmo_deal() DataOut:\n%s\n", Vcmowrap.wcmoarg_get_string( wcmoarg_DataOut ) ) ;

DONE_ACTION:

/***********************************/
/*   Close the Wrapper instance    */
/***********************************/

if ( initialized )
    Vcmowrap.wcmo_exit( wcmoarg_Handle, wcmoarg_User, wcmoarg_DataOut, wcmoarg_ErrOut ) ;

/***********************************/
/*          Free WCMOARGs          */
/***********************************/

Vcmowrap.wcmoarg_free( wcmoarg_Handle  ) ;
Vcmowrap.wcmoarg_free( wcmoarg_User    ) ;
Vcmowrap.wcmoarg_free( wcmoarg_Deal    ) ;
Vcmowrap.wcmoarg_free( wcmoarg_Options ) ;
Vcmowrap.wcmoarg_free( wcmoarg_Cashflow ) ;
Vcmowrap.wcmoarg_free( wcmoarg_Loanscen ) ;
Vcmowrap.wcmoarg_free( wcmoarg_Propscen ) ;
Vcmowrap.wcmoarg_free( wcmoarg_Stats ) ;
Vcmowrap.wcmoarg_free( wcmoarg_Unused1 ) ;
Vcmowrap.wcmoarg_free( wcmoarg_Unused2 ) ;
Vcmowrap.wcmoarg_free( wcmoarg_DataOut ) ;
Vcmowrap.wcmoarg_free( wcmoarg_ErrOut  ) ;

if ( vcmowrapModule != NULL )
    WCMOFreeModule( vcmowrapModule ) ;

return retval ;
}
