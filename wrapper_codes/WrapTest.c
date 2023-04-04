#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wcmoapi.h"


#if defined(MS_WINNT)

#define CDI_PATH         "s:\\cmo_cdi"
#define CDU_PATH         "s:\\cmo_cdu"

#elif defined(LINUX)

#define CDI_PATH         "/home/database/data/source/cmo_cdi"
#define CDU_PATH         "/home/database/data/source/cmo_cdu"

#elif defined(SOLARIS)

#define CDI_PATH         "/mnt/fin/data/source/cmo_cdi"
#define CDU_PATH         "/mnt/fin/data/source/cmo_cdu"

#endif


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

if ( (cpos = wcmoarg_get_string( wcmoarg )) != NULL )
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

/***********************************/
/*        Allocate WCMOARGs        */
/***********************************/

wcmoarg_alloc( wcmoarg_Handle  ) ;
wcmoarg_alloc( wcmoarg_User    ) ;
wcmoarg_alloc( wcmoarg_Deal    ) ;
wcmoarg_alloc( wcmoarg_Options ) ;
wcmoarg_alloc( wcmoarg_Cashflow ) ;
wcmoarg_alloc( wcmoarg_Loanscen ) ;
wcmoarg_alloc( wcmoarg_Propscen ) ;
wcmoarg_alloc( wcmoarg_Stats ) ;
wcmoarg_alloc( wcmoarg_Unused1 ) ;
wcmoarg_alloc( wcmoarg_Unused2 ) ;
wcmoarg_alloc( wcmoarg_DataOut ) ;
wcmoarg_alloc( wcmoarg_ErrOut  ) ;

/***********************************/
/* Initialize the Wrapper instance */
/***********************************/

wcmoarg_set_string( wcmoarg_Handle,
"KEYVAL_DELIM_ASCII=10\n"     /* Use '\n' (= char(10)), so argument strings will look good when printed to screen */
 ) ;

if ( wcmo_init( wcmoarg_Handle, wcmoarg_User, wcmoarg_DataOut, wcmoarg_ErrOut ) )
    {
    fprintf( stderr, "\n\nwcmo_init() ErrOut:\n%s\n", wcmoarg_get_string( wcmoarg_ErrOut ) ) ;
    retval = EXIT_FAILURE ;
    goto DONE_ACTION ;
    }
else
    printf( "\n\nwcmo_init() DataOut:\n%s\n", wcmoarg_get_string( wcmoarg_DataOut ) ) ;

initialized = 1 ;


/***********************************/
/*         Parse the deal          */
/***********************************/

wcmoarg_set_string( wcmoarg_Options,
"CDI_PATH=" CDI_PATH "\n"
"CDU_PATH=" CDU_PATH "\n"
) ;

wcmoarg_set_string( wcmoarg_Deal,
"DEAL_NAME=fhl034\n"
"DEAL_MODE=NEW\n"
) ;

if ( wcmo_deal( wcmoarg_Handle, wcmoarg_User, wcmoarg_Options, wcmoarg_Deal, wcmoarg_DataOut, wcmoarg_ErrOut ) )
    {
    fprintf( stderr, "\n\nwcmo_deal() ErrOut:\n%s\n", wcmoarg_get_string( wcmoarg_ErrOut ) ) ;
    retval = EXIT_FAILURE ;
    goto DONE_ACTION ;
    }
else
    printf( "\n\nwcmo_deal() DataOut:\n%s\n", wcmoarg_get_string( wcmoarg_DataOut ) ) ;

DONE_ACTION:

/***********************************/
/*   Close the Wrapper instance    */
/***********************************/

if ( initialized )
    wcmo_exit( wcmoarg_Handle, wcmoarg_User, wcmoarg_DataOut, wcmoarg_ErrOut ) ;

/***********************************/
/*          Free WCMOARGs          */
/***********************************/

wcmoarg_free( wcmoarg_Handle  ) ;
wcmoarg_free( wcmoarg_User    ) ;
wcmoarg_free( wcmoarg_Deal    ) ;
wcmoarg_free( wcmoarg_Options ) ;
wcmoarg_free( wcmoarg_Cashflow ) ;
wcmoarg_free( wcmoarg_Loanscen ) ;
wcmoarg_free( wcmoarg_Propscen ) ;
wcmoarg_free( wcmoarg_Stats ) ;
wcmoarg_free( wcmoarg_Unused1 ) ;
wcmoarg_free( wcmoarg_Unused2 ) ;
wcmoarg_free( wcmoarg_DataOut ) ;
wcmoarg_free( wcmoarg_ErrOut  ) ;

return retval ;
}
