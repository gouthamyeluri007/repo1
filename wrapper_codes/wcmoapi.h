#ifndef _WCMOAPI_H
#define _WCMOAPI_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(MS_WINNT) || defined(WIN32)

#include <windows.h>

typedef BSTR     WCMOARG ;
typedef HMODULE  WCMOModule ;

#define STDCALL __stdcall

#define WCMOLoadModule( modulename )                 LoadLibrary( (modulename) )
#define WCMOFindModule( modulename )                 GetModuleHandle( (modulename) )
#define WCMOLoadSymbol( module, symbol )             GetProcAddress( (module), (symbol) )
#define WCMOFreeModule( module )                     FreeLibrary( (module) )

#else  /* Linux or Unix */

#include <dlfcn.h>

typedef char *   WCMOARG ;
typedef void *   WCMOModule ;

#define STDCALL

#define WCMOLoadModule( modulename )                 dlopen( (modulename), RTLD_LAZY )
#define WCMOFindModule( modulename )                 dlopen( (modulename), RTLD_LAZY|RTLD_NOLOAD )
#define WCMOLoadSymbol( module, symbol )             dlsym( (module), (symbol) )
#define WCMOFreeModule( module )                     dlclose( (module) )

#endif



#define WCMOARG1  ( WCMOARG * )
#define WCMOARG2  ( WCMOARG *, WCMOARG * )
#define WCMOARG3  ( WCMOARG *, WCMOARG *, WCMOARG * )
#define WCMOARG4  ( WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG * )
#define WCMOARG5  ( WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG * )
#define WCMOARG6  ( WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG * )
#define WCMOARG7  ( WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG * )
#define WCMOARG8  ( WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG * )
#define WCMOARG9  ( WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG * )
#define WCMOARG10 ( WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG *, WCMOARG * )


/* DECLARE_WCMOFCN: Prototypes functions, and creates per-function FCN_wcmo_xxx typedefs */
#define DECLARE_WCMOFCN( retval, fcnname, arglist )                                  \
retval STDCALL fcnname arglist ;                    /* Function Prototype */         \
typedef retval (STDCALL * FCN_##fcnname) arglist ;  /* Function pointer typedef */


DECLARE_WCMOFCN( int,     wcmo_init,                              WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_exit,                              WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_deal,                              WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_cashflow,                          WCMOARG9 )
DECLARE_WCMOFCN( int,     wcmo_stats,                             WCMOARG8 )
DECLARE_WCMOFCN( int,     wcmo_split_string,                      WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_atoi,                              WCMOARG1 )
DECLARE_WCMOFCN( double,  wcmo_atof,                              WCMOARG1 )
DECLARE_WCMOFCN( int,     wcmo_collat,                            WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_tree,                              WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_abs_summary,                       WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_read_file_into_buff,               WCMOARG3 )
DECLARE_WCMOFCN( int,     wcmo_pathgen,                           WCMOARG8 )
DECLARE_WCMOFCN( int,     wcmo_oas,                               WCMOARG10 )
DECLARE_WCMOFCN( int,     wcmo_propinfo,                          WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_is_valid_path,                     WCMOARG8 )
DECLARE_WCMOFCN( int,     wcmo_make_grid_vect,                    WCMOARG2 )
DECLARE_WCMOFCN( long,    wcmo_atol,                              WCMOARG1 )
DECLARE_WCMOFCN( int,     wcmo_wake_up,                           WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_price_format,                      WCMOARG3 )
DECLARE_WCMOFCN( int,     wcmo_file_list,                         WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_sort_strvect,                      WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_fix_gridclip,                      WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_remittance,                        WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_database_tree,                     WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_business_date_adj,                 WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_dbstatus,                          WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_YyyyMmDd_diff,                     ( int, int, int ) )
DECLARE_WCMOFCN( void *,  wcmo_address_of_double,                 ( double * ) )
DECLARE_WCMOFCN( int,     wcmo_portf_setup,                       WCMOARG6 )
DECLARE_WCMOFCN( void,    wcmo_memcpy,                            ( char *, char *, int ) )
DECLARE_WCMOFCN( int,     wcmo_set_progbar,                       WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_callpro,                           WCMOARG7 )
DECLARE_WCMOFCN( int,     wcmo_history,                           WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_replace_bad_chars,                 WCMOARG1 )
DECLARE_WCMOFCN( int,     wcmo_cluster_loans_into_pools,          WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_daycount,                          ( WCMOARG *, WCMOARG *, int, int ) )
DECLARE_WCMOFCN( int,     wcmo_portf_strat_entry,                 WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_replace_in_collat_rec,             WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_build_cdx_rec,                     WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_trigseries,                        WCMOARG7 )
DECLARE_WCMOFCN( int,     wcmo_collcf,                            WCMOARG7 )
DECLARE_WCMOFCN( int,     wcmo_read_cdx,                          WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_create_cdx_header,                 WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_filter_cdx,                        WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_change_cdx,                        WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_moodybet,                          WCMOARG9 )
DECLARE_WCMOFCN( int,     wcmo_vector_product,                    WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_collars,                           WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_interpolate,                       WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_extinfo,                           WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_deal_info,                         WCMOARG6 )
DECLARE_WCMOFCN( long,    wcmo_get_ith_instance_pos,              ( WCMOARG *, WCMOARG *, long ) )
DECLARE_WCMOFCN( int,     wcmo_create_cdu,                        WCMOARG8 )
DECLARE_WCMOFCN( int,     wcmo_set_script,                        WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_convert_rate_curve,                WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_breakeven_analysis,                WCMOARG9 )
DECLARE_WCMOFCN( int,     wcmo_uexp_catalog,                      WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_vector_elements,                   WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_set_asset_data,                    WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_collat_split,                      WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_ucollat_subset_catalog,            WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_uentity_catalog,                   WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_dll_version,                       WCMOARG2 )

DECLARE_WCMOFCN( void,    wcmoarg_alloc,                          WCMOARG1 )
DECLARE_WCMOFCN( void,    wcmoarg_set_string,                     ( WCMOARG *, char * ) )
DECLARE_WCMOFCN( void,    wcmoarg_append_string,                  ( WCMOARG *, char * ) )
DECLARE_WCMOFCN( char *,  wcmoarg_get_string,                     WCMOARG1 )
DECLARE_WCMOFCN( void,    wcmoarg_free,                           WCMOARG1 )
DECLARE_WCMOFCN( int,     wcmo_get_cf_events,                     WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_cdoeval_query_deal,                WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_cdoeval_run_evaluator,             WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_user_function,                     ( WCMOARG *, WCMOARG *, int, WCMOARG *, WCMOARG * ) )
DECLARE_WCMOFCN( int,     wcmouser_set_passthru,                  ( WCMOARG *, int, WCMOARG *, WCMOARG * ) )
DECLARE_WCMOFCN( int,     wcmouser_get_passthru,                  ( WCMOARG *, int, WCMOARG *, WCMOARG * ) )
DECLARE_WCMOFCN( int,     wcmouser_set_dataout,                   WCMOARG3 )
DECLARE_WCMOFCN( int,     wcmouser_set_error,                     WCMOARG3 )
DECLARE_WCMOFCN( int,     wcmo_fitch_breakevens,                  WCMOARG9 )
DECLARE_WCMOFCN( int,     wcmo_modify_deal_collat,                WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_replace_collat,                    WCMOARG6 )
DECLARE_WCMOFCN( int,     wcmo_fitchvec_query_deal,               WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_fitchvec_run_vector,               WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_waterfall_report,                  WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_cluster_collat,                    WCMOARG5 )
DECLARE_WCMOFCN( int,     wcmo_interrogate_thread,                WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_error_requires_reload,             WCMOARG3 )
DECLARE_WCMOFCN( int,     wcmo_socket,                            WCMOARG4 )
DECLARE_WCMOFCN( int,     wcmo_make_bond_split_forecasted,        WCMOARG8 )



/* WCMOFCN_ELEMENT: Declares a function pointer to have a type appropriate */
/*     to the function to which it is intended to point.                   */
#define WCMOFCN_ELEMENT( fcnname ) FCN_##fcnname fcnname

/* VCMOWRAP_FCN: A structure with fields named and typed to the public       */
/*     functions exported by VCMOWRAP, to assist dynamic linking and loading */

typedef struct {
    WCMOFCN_ELEMENT( wcmo_init ) ;
    WCMOFCN_ELEMENT( wcmo_exit ) ;
    WCMOFCN_ELEMENT( wcmo_deal ) ;
    WCMOFCN_ELEMENT( wcmo_cashflow ) ;
    WCMOFCN_ELEMENT( wcmo_stats ) ;
    WCMOFCN_ELEMENT( wcmo_split_string ) ;
    WCMOFCN_ELEMENT( wcmo_atoi ) ;
    WCMOFCN_ELEMENT( wcmo_atof ) ;
    WCMOFCN_ELEMENT( wcmo_collat ) ;
    WCMOFCN_ELEMENT( wcmo_tree ) ;
    WCMOFCN_ELEMENT( wcmo_abs_summary ) ;
    WCMOFCN_ELEMENT( wcmo_read_file_into_buff ) ;
    WCMOFCN_ELEMENT( wcmo_pathgen ) ;
    WCMOFCN_ELEMENT( wcmo_oas ) ;
    WCMOFCN_ELEMENT( wcmo_propinfo ) ;
    WCMOFCN_ELEMENT( wcmo_is_valid_path ) ;
    WCMOFCN_ELEMENT( wcmo_make_grid_vect ) ;
    WCMOFCN_ELEMENT( wcmo_atol ) ;
    WCMOFCN_ELEMENT( wcmo_wake_up ) ;
    WCMOFCN_ELEMENT( wcmo_price_format ) ;
    WCMOFCN_ELEMENT( wcmo_file_list ) ;
    WCMOFCN_ELEMENT( wcmo_sort_strvect ) ;
    WCMOFCN_ELEMENT( wcmo_fix_gridclip ) ;
    WCMOFCN_ELEMENT( wcmo_remittance ) ;
    WCMOFCN_ELEMENT( wcmo_database_tree ) ;
    WCMOFCN_ELEMENT( wcmo_business_date_adj ) ;
    WCMOFCN_ELEMENT( wcmo_dbstatus ) ;
    WCMOFCN_ELEMENT( wcmo_YyyyMmDd_diff ) ;
    WCMOFCN_ELEMENT( wcmo_address_of_double ) ;
    WCMOFCN_ELEMENT( wcmo_portf_setup ) ;
    WCMOFCN_ELEMENT( wcmo_memcpy ) ;
    WCMOFCN_ELEMENT( wcmo_set_progbar ) ;
    WCMOFCN_ELEMENT( wcmo_callpro ) ;
    WCMOFCN_ELEMENT( wcmo_history ) ;
    WCMOFCN_ELEMENT( wcmo_replace_bad_chars ) ;
    WCMOFCN_ELEMENT( wcmo_cluster_loans_into_pools ) ;
    WCMOFCN_ELEMENT( wcmo_daycount ) ;
    WCMOFCN_ELEMENT( wcmo_portf_strat_entry ) ;
    WCMOFCN_ELEMENT( wcmo_replace_in_collat_rec ) ;
    WCMOFCN_ELEMENT( wcmo_build_cdx_rec ) ;
    WCMOFCN_ELEMENT( wcmo_trigseries ) ;
    WCMOFCN_ELEMENT( wcmo_collcf ) ;
    WCMOFCN_ELEMENT( wcmo_read_cdx ) ;
    WCMOFCN_ELEMENT( wcmo_create_cdx_header ) ;
    WCMOFCN_ELEMENT( wcmo_filter_cdx ) ;
    WCMOFCN_ELEMENT( wcmo_change_cdx ) ;
    WCMOFCN_ELEMENT( wcmo_moodybet ) ;
    WCMOFCN_ELEMENT( wcmo_vector_product ) ;
    WCMOFCN_ELEMENT( wcmo_collars ) ;
    WCMOFCN_ELEMENT( wcmo_interpolate ) ;
    WCMOFCN_ELEMENT( wcmo_extinfo ) ;
    WCMOFCN_ELEMENT( wcmo_deal_info ) ;
    WCMOFCN_ELEMENT( wcmo_get_ith_instance_pos ) ;
    WCMOFCN_ELEMENT( wcmo_create_cdu ) ;
    WCMOFCN_ELEMENT( wcmo_set_script ) ;
    WCMOFCN_ELEMENT( wcmo_convert_rate_curve ) ;
    WCMOFCN_ELEMENT( wcmo_breakeven_analysis ) ;
    WCMOFCN_ELEMENT( wcmo_uexp_catalog ) ;
    WCMOFCN_ELEMENT( wcmo_vector_elements ) ;
    WCMOFCN_ELEMENT( wcmo_set_asset_data ) ;
    WCMOFCN_ELEMENT( wcmo_collat_split ) ;
    WCMOFCN_ELEMENT( wcmo_ucollat_subset_catalog ) ;
    WCMOFCN_ELEMENT( wcmo_uentity_catalog ) ;
    WCMOFCN_ELEMENT( wcmo_dll_version ) ;

    WCMOFCN_ELEMENT( wcmoarg_alloc ) ;
    WCMOFCN_ELEMENT( wcmoarg_set_string ) ;
    WCMOFCN_ELEMENT( wcmoarg_append_string ) ;
    WCMOFCN_ELEMENT( wcmoarg_get_string ) ;
    WCMOFCN_ELEMENT( wcmoarg_free ) ;
    WCMOFCN_ELEMENT( wcmo_get_cf_events ) ;
    WCMOFCN_ELEMENT( wcmo_cdoeval_query_deal ) ;
    WCMOFCN_ELEMENT( wcmo_cdoeval_run_evaluator ) ;
    WCMOFCN_ELEMENT( wcmo_user_function ) ;
    WCMOFCN_ELEMENT( wcmouser_set_passthru ) ;
    WCMOFCN_ELEMENT( wcmouser_get_passthru ) ;
    WCMOFCN_ELEMENT( wcmouser_set_dataout ) ;
    WCMOFCN_ELEMENT( wcmouser_set_error ) ;
    WCMOFCN_ELEMENT( wcmo_fitch_breakevens ) ;
    WCMOFCN_ELEMENT( wcmo_modify_deal_collat ) ;
    WCMOFCN_ELEMENT( wcmo_replace_collat ) ;
    WCMOFCN_ELEMENT( wcmo_fitchvec_query_deal ) ;
    WCMOFCN_ELEMENT( wcmo_fitchvec_run_vector ) ;
    WCMOFCN_ELEMENT( wcmo_waterfall_report ) ;
    WCMOFCN_ELEMENT( wcmo_cluster_collat ) ;
    WCMOFCN_ELEMENT( wcmo_interrogate_thread ) ;
    WCMOFCN_ELEMENT( wcmo_error_requires_reload ) ;
    WCMOFCN_ELEMENT( wcmo_socket ) ;
    WCMOFCN_ELEMENT( wcmo_make_bond_split_forecasted ) ;

} VCMOWRAP_FCN ;


#undef DECLARE_WCMOFCN
#undef WCMOFCN_ELEMENT

#ifdef __cplusplus
}
#endif

#endif
