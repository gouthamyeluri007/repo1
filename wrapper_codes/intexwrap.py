import os
import sys
from ctypes import *

if os.name == "posix":
    library = os.path.join(os.getcwd(), "./wrapper_codes/libvcmowrap.so")
    VCMOWRAP = CDLL(library)
elif os.name == "nt":
    if sizeof(c_void_p) == 8:
        library = "vcmowr64"  # 64-bit Windows
    else:
        library = "vcmowrap"  # 32-bit Windows
    VCMOWRAP = WinDLL(library)


WCMOARG1 = [c_void_p]
WCMOARG2 = [c_void_p, c_void_p]
WCMOARG3 = [c_void_p, c_void_p, c_void_p]
WCMOARG4 = [c_void_p, c_void_p, c_void_p, c_void_p]
WCMOARG5 = [c_void_p, c_void_p, c_void_p, c_void_p, c_void_p]
WCMOARG6 = [c_void_p, c_void_p, c_void_p, c_void_p, c_void_p, c_void_p]
WCMOARG7 = [c_void_p, c_void_p, c_void_p, c_void_p, c_void_p, c_void_p, c_void_p]
WCMOARG8 = [
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
]
WCMOARG9 = [
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
]
WCMOARG10 = [
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
    c_void_p,
]

_wcmoarg_alloc = VCMOWRAP.wcmoarg_alloc
_wcmoarg_alloc.restype = None
_wcmoarg_alloc.argtypes = WCMOARG1
_wcmoarg_set_string = VCMOWRAP.wcmoarg_set_string
_wcmoarg_set_string.restype = None
_wcmoarg_set_string.argtypes = [c_void_p, c_char_p]
_wcmoarg_append_string = VCMOWRAP.wcmoarg_append_string
_wcmoarg_append_string.restype = None
_wcmoarg_append_string.argtypes = [c_void_p, c_char_p]
_wcmoarg_get_string = VCMOWRAP.wcmoarg_get_string
_wcmoarg_get_string.restype = c_char_p
_wcmoarg_get_string.argtypes = WCMOARG1
_wcmoarg_free = VCMOWRAP.wcmoarg_free
_wcmoarg_free.restype = None
_wcmoarg_free.argtypes = WCMOARG1
_wcmo_init = VCMOWRAP.wcmo_init
_wcmo_init.restype = c_int
_wcmo_init.argtypes = WCMOARG4
_wcmo_exit = VCMOWRAP.wcmo_exit
_wcmo_exit.restype = c_int
_wcmo_exit.argtypes = WCMOARG4
_wcmo_deal = VCMOWRAP.wcmo_deal
_wcmo_deal.restype = c_int
_wcmo_deal.argtypes = WCMOARG6
_wcmo_cashflow = VCMOWRAP.wcmo_cashflow
_wcmo_cashflow.restype = c_int
_wcmo_cashflow.argtypes = WCMOARG9
_wcmo_stats = VCMOWRAP.wcmo_stats
_wcmo_stats.restype = c_int
_wcmo_stats.argtypes = WCMOARG8
_wcmo_split_string = VCMOWRAP.wcmo_split_string
_wcmo_split_string.restype = c_int
_wcmo_split_string.argtypes = WCMOARG5
_wcmo_atoi = VCMOWRAP.wcmo_atoi
_wcmo_atoi.restype = c_int
_wcmo_atoi.argtypes = WCMOARG1
_wcmo_atof = VCMOWRAP.wcmo_atof
_wcmo_atof.restype = c_double
_wcmo_atof.argtypes = WCMOARG1
_wcmo_collat = VCMOWRAP.wcmo_collat
_wcmo_collat.restype = c_int
_wcmo_collat.argtypes = WCMOARG6
_wcmo_tree = VCMOWRAP.wcmo_tree
_wcmo_tree.restype = c_int
_wcmo_tree.argtypes = WCMOARG6
_wcmo_abs_summary = VCMOWRAP.wcmo_abs_summary
_wcmo_abs_summary.restype = c_int
_wcmo_abs_summary.argtypes = WCMOARG6
_wcmo_read_file_into_buff = VCMOWRAP.wcmo_read_file_into_buff
_wcmo_read_file_into_buff.restype = c_int
_wcmo_read_file_into_buff.argtypes = WCMOARG3
_wcmo_pathgen = VCMOWRAP.wcmo_pathgen
_wcmo_pathgen.restype = c_int
_wcmo_pathgen.argtypes = WCMOARG8
_wcmo_oas = VCMOWRAP.wcmo_oas
_wcmo_oas.restype = c_int
_wcmo_oas.argtypes = WCMOARG10
_wcmo_propinfo = VCMOWRAP.wcmo_propinfo
_wcmo_propinfo.restype = c_int
_wcmo_propinfo.argtypes = WCMOARG6
_wcmo_make_grid_vect = VCMOWRAP.wcmo_make_grid_vect
_wcmo_make_grid_vect.restype = c_int
_wcmo_make_grid_vect.argtypes = WCMOARG2
_wcmo_atol = VCMOWRAP.wcmo_atol
_wcmo_atol.restype = c_long
_wcmo_atol.argtypes = WCMOARG1
_wcmo_wake_up = VCMOWRAP.wcmo_wake_up
_wcmo_wake_up.restype = c_int
_wcmo_wake_up.argtypes = WCMOARG4
_wcmo_price_format = VCMOWRAP.wcmo_price_format
_wcmo_price_format.restype = c_int
_wcmo_price_format.argtypes = WCMOARG3
_wcmo_sort_strvect = VCMOWRAP.wcmo_sort_strvect
_wcmo_sort_strvect.restype = c_int
_wcmo_sort_strvect.argtypes = WCMOARG5
_wcmo_fix_gridclip = VCMOWRAP.wcmo_fix_gridclip
_wcmo_fix_gridclip.restype = c_int
_wcmo_fix_gridclip.argtypes = WCMOARG5
_wcmo_remittance = VCMOWRAP.wcmo_remittance
_wcmo_remittance.restype = c_int
_wcmo_remittance.argtypes = WCMOARG6
_wcmo_database_tree = VCMOWRAP.wcmo_database_tree
_wcmo_database_tree.restype = c_int
_wcmo_database_tree.argtypes = WCMOARG5
_wcmo_business_date_adj = VCMOWRAP.wcmo_business_date_adj
_wcmo_business_date_adj.restype = c_int
_wcmo_business_date_adj.argtypes = WCMOARG5
_wcmo_dbstatus = VCMOWRAP.wcmo_dbstatus
_wcmo_dbstatus.restype = c_int
_wcmo_dbstatus.argtypes = WCMOARG4
_wcmo_YyyyMmDd_diff = VCMOWRAP.wcmo_YyyyMmDd_diff
_wcmo_YyyyMmDd_diff.restype = c_int
_wcmo_YyyyMmDd_diff.argtypes = [c_int, c_int, c_int]
_wcmo_address_of_double = VCMOWRAP.wcmo_address_of_double
_wcmo_address_of_double.restype = c_void_p
_wcmo_address_of_double.argtypes = [c_void_p]
_wcmo_portf_setup = VCMOWRAP.wcmo_portf_setup
_wcmo_portf_setup.restype = c_int
_wcmo_portf_setup.argtypes = WCMOARG6
_wcmo_memcpy = VCMOWRAP.wcmo_memcpy
_wcmo_memcpy.restype = None
_wcmo_memcpy.argtypes = [c_char_p, c_char_p, c_int]
_wcmo_set_progbar = VCMOWRAP.wcmo_set_progbar
_wcmo_set_progbar.restype = c_int
_wcmo_set_progbar.argtypes = WCMOARG4
_wcmo_callpro = VCMOWRAP.wcmo_callpro
_wcmo_callpro.restype = c_int
_wcmo_callpro.argtypes = WCMOARG7
_wcmo_history = VCMOWRAP.wcmo_history
_wcmo_history.restype = c_int
_wcmo_history.argtypes = WCMOARG6
_wcmo_replace_bad_chars = VCMOWRAP.wcmo_replace_bad_chars
_wcmo_replace_bad_chars.restype = c_int
_wcmo_replace_bad_chars.argtypes = WCMOARG1
_wcmo_cluster_loans_into_pools = VCMOWRAP.wcmo_cluster_loans_into_pools
_wcmo_cluster_loans_into_pools.restype = c_int
_wcmo_cluster_loans_into_pools.argtypes = WCMOARG4
_wcmo_daycount = VCMOWRAP.wcmo_daycount
_wcmo_daycount.restype = c_int
_wcmo_daycount.argtypes = [c_void_p, c_void_p, c_int, c_int]
_wcmo_idsys = VCMOWRAP.wcmo_idsys
_wcmo_idsys.restype = c_int
_wcmo_idsys.argtypes = WCMOARG4
_wcmo_portf_strat_entry = VCMOWRAP.wcmo_portf_strat_entry
_wcmo_portf_strat_entry.restype = c_int
_wcmo_portf_strat_entry.argtypes = WCMOARG6
_wcmo_replace_in_collat_rec = VCMOWRAP.wcmo_replace_in_collat_rec
_wcmo_replace_in_collat_rec.restype = c_int
_wcmo_replace_in_collat_rec.argtypes = WCMOARG5
_wcmo_build_cdx_rec = VCMOWRAP.wcmo_build_cdx_rec
_wcmo_build_cdx_rec.restype = c_int
_wcmo_build_cdx_rec.argtypes = WCMOARG5
_wcmo_trigseries = VCMOWRAP.wcmo_trigseries
_wcmo_trigseries.restype = c_int
_wcmo_trigseries.argtypes = WCMOARG7
_wcmo_collcf = VCMOWRAP.wcmo_collcf
_wcmo_collcf.restype = c_int
_wcmo_collcf.argtypes = WCMOARG7
_wcmo_read_cdx = VCMOWRAP.wcmo_read_cdx
_wcmo_read_cdx.restype = c_int
_wcmo_read_cdx.argtypes = WCMOARG4
_wcmo_create_cdx_header = VCMOWRAP.wcmo_create_cdx_header
_wcmo_create_cdx_header.restype = c_int
_wcmo_create_cdx_header.argtypes = WCMOARG4
_wcmo_filter_cdx = VCMOWRAP.wcmo_filter_cdx
_wcmo_filter_cdx.restype = c_int
_wcmo_filter_cdx.argtypes = WCMOARG4
_wcmo_change_cdx = VCMOWRAP.wcmo_change_cdx
_wcmo_change_cdx.restype = c_int
_wcmo_change_cdx.argtypes = WCMOARG4
_wcmo_moodybet = VCMOWRAP.wcmo_moodybet
_wcmo_moodybet.restype = c_int
_wcmo_moodybet.argtypes = WCMOARG9
_wcmo_vector_product = VCMOWRAP.wcmo_vector_product
_wcmo_vector_product.restype = c_int
_wcmo_vector_product.argtypes = WCMOARG4
_wcmo_collars = VCMOWRAP.wcmo_collars
_wcmo_collars.restype = c_int
_wcmo_collars.argtypes = WCMOARG6
_wcmo_interpolate = VCMOWRAP.wcmo_interpolate
_wcmo_interpolate.restype = c_int
_wcmo_interpolate.argtypes = WCMOARG6
_wcmo_extinfo = VCMOWRAP.wcmo_extinfo
_wcmo_extinfo.restype = c_int
_wcmo_extinfo.argtypes = WCMOARG4
_wcmo_deal_info = VCMOWRAP.wcmo_deal_info
_wcmo_deal_info.restype = c_int
_wcmo_deal_info.argtypes = WCMOARG6
_wcmo_get_ith_instance_pos = VCMOWRAP.wcmo_get_ith_instance_pos
_wcmo_get_ith_instance_pos.restype = c_long
_wcmo_get_ith_instance_pos.argtypes = [c_void_p, c_void_p, c_long]
_wcmo_create_cdu = VCMOWRAP.wcmo_create_cdu
_wcmo_create_cdu.restype = c_int
_wcmo_create_cdu.argtypes = WCMOARG8
_wcmo_set_script = VCMOWRAP.wcmo_set_script
_wcmo_set_script.restype = c_int
_wcmo_set_script.argtypes = WCMOARG6
_wcmo_convert_rate_curve = VCMOWRAP.wcmo_convert_rate_curve
_wcmo_convert_rate_curve.restype = c_int
_wcmo_convert_rate_curve.argtypes = WCMOARG6
_wcmo_breakeven_analysis = VCMOWRAP.wcmo_breakeven_analysis
_wcmo_breakeven_analysis.restype = c_int
_wcmo_breakeven_analysis.argtypes = WCMOARG9
_wcmo_uexp_catalog = VCMOWRAP.wcmo_uexp_catalog
_wcmo_uexp_catalog.restype = c_int
_wcmo_uexp_catalog.argtypes = WCMOARG6
_wcmo_vector_elements = VCMOWRAP.wcmo_vector_elements
_wcmo_vector_elements.restype = c_int
_wcmo_vector_elements.argtypes = WCMOARG4
_wcmo_set_asset_data = VCMOWRAP.wcmo_set_asset_data
_wcmo_set_asset_data.restype = c_int
_wcmo_set_asset_data.argtypes = WCMOARG6
_wcmo_collat_split = VCMOWRAP.wcmo_collat_split
_wcmo_collat_split.restype = c_int
_wcmo_collat_split.argtypes = WCMOARG6
_wcmo_ucollat_subset_catalog = VCMOWRAP.wcmo_ucollat_subset_catalog
_wcmo_ucollat_subset_catalog.restype = c_int
_wcmo_ucollat_subset_catalog.argtypes = WCMOARG6
_wcmo_uentity_catalog = VCMOWRAP.wcmo_uentity_catalog
_wcmo_uentity_catalog.restype = c_int
_wcmo_uentity_catalog.argtypes = WCMOARG6
_wcmo_dll_version = VCMOWRAP.wcmo_dll_version
_wcmo_dll_version.restype = c_int
_wcmo_dll_version.argtypes = WCMOARG2
_wcmo_get_cf_events = VCMOWRAP.wcmo_get_cf_events
_wcmo_get_cf_events.restype = c_int
_wcmo_get_cf_events.argtypes = WCMOARG5
_wcmo_cdoeval_query_deal = VCMOWRAP.wcmo_cdoeval_query_deal
_wcmo_cdoeval_query_deal.restype = c_int
_wcmo_cdoeval_query_deal.argtypes = WCMOARG5
_wcmo_cdoeval_run_evaluator = VCMOWRAP.wcmo_cdoeval_run_evaluator
_wcmo_cdoeval_run_evaluator.restype = c_int
_wcmo_cdoeval_run_evaluator.argtypes = WCMOARG5
_wcmo_user_function = VCMOWRAP.wcmo_user_function
_wcmo_user_function.restype = c_int
_wcmo_user_function.argtypes = [c_void_p, c_void_p, c_int, c_void_p, c_void_p]
_wcmouser_set_passthru = VCMOWRAP.wcmouser_set_passthru
_wcmouser_set_passthru.restype = c_int
_wcmouser_set_passthru.argtypes = [c_void_p, c_int, c_void_p, c_void_p]
_wcmouser_get_passthru = VCMOWRAP.wcmouser_get_passthru
_wcmouser_get_passthru.restype = c_int
_wcmouser_get_passthru.argtypes = [c_void_p, c_int, c_void_p, c_void_p]
_wcmouser_set_dataout = VCMOWRAP.wcmouser_set_dataout
_wcmouser_set_dataout.restype = c_int
_wcmouser_set_dataout.argtypes = WCMOARG3
_wcmouser_set_error = VCMOWRAP.wcmouser_set_error
_wcmouser_set_error.restype = c_int
_wcmouser_set_error.argtypes = WCMOARG3
_wcmo_fitch_breakevens = VCMOWRAP.wcmo_fitch_breakevens
_wcmo_fitch_breakevens.restype = c_int
_wcmo_fitch_breakevens.argtypes = WCMOARG9
_wcmo_modify_deal_collat = VCMOWRAP.wcmo_modify_deal_collat
_wcmo_modify_deal_collat.restype = c_int
_wcmo_modify_deal_collat.argtypes = WCMOARG6
_wcmo_replace_collat = VCMOWRAP.wcmo_replace_collat
_wcmo_replace_collat.restype = c_int
_wcmo_replace_collat.argtypes = WCMOARG6
_wcmo_fitchvec_query_deal = VCMOWRAP.wcmo_fitchvec_query_deal
_wcmo_fitchvec_query_deal.restype = c_int
_wcmo_fitchvec_query_deal.argtypes = WCMOARG5
_wcmo_fitchvec_run_vector = VCMOWRAP.wcmo_fitchvec_run_vector
_wcmo_fitchvec_run_vector.restype = c_int
_wcmo_fitchvec_run_vector.argtypes = WCMOARG5
_wcmo_waterfall_report = VCMOWRAP.wcmo_waterfall_report
_wcmo_waterfall_report.restype = c_int
_wcmo_waterfall_report.argtypes = WCMOARG5
_wcmo_cluster_collat = VCMOWRAP.wcmo_cluster_collat
_wcmo_cluster_collat.restype = c_int
_wcmo_cluster_collat.argtypes = WCMOARG5
_wcmo_interrogate_thread = VCMOWRAP.wcmo_interrogate_thread
_wcmo_interrogate_thread.restype = c_int
_wcmo_interrogate_thread.argtypes = WCMOARG4
_wcmo_error_requires_reload = VCMOWRAP.wcmo_error_requires_reload
_wcmo_error_requires_reload.restype = c_int
_wcmo_error_requires_reload.argtypes = WCMOARG3
_wcmo_socket = VCMOWRAP.wcmo_socket
_wcmo_socket.restype = c_int
_wcmo_socket.argtypes = WCMOARG4


def _set_WCMOarg_to__warg(WCMOarg_xxx, wargxxx_ref):
    if not WCMOarg_xxx:
        WCMOarg_xxx = ""
    _wcmoarg_set_string(
        wargxxx_ref, WCMOarg_xxx.encode(encoding="utf-8", errors="replace")
    )


def _get_WCMOarg_from__warg(wargxxx_ref):
    return _wcmoarg_get_string(wargxxx_ref).decode()


def KeyValDict(KVargstring):
    """KeyValDict:  From an input newline-delimited keyword=value string, populates and returns
    a dictionary object containing the Intex Wrapper API arguments

    Args:
        KVargstring:  The newline-delimited keyword=value string

    Returns:
        KVdict:  The input string parsed into a keyword, value dictionary
    """
    KVdict = dict()

    for kv in KVargstring.split("\n"):
        if not kv:
            continue

        inSubscript = False
        kvlen = len(kv)
        for index in range(kvlen - 1):
            if inSubscript and kv[index] == "]":
                inSubscript = False
            elif not inSubscript:
                if kv[index] == "[":
                    inSubscript = True
                elif kv[index] == "=":
                    break

        if index > 0:
            if index < kvlen - 1:
                KVdict[kv[:index]] = kv[index + 1 :]
            elif index == kvlen - 1:
                KVdict[kv[:index]] = ""

    return KVdict


def KeyValArgString(KVdict):
    """KeyValArgString: From an input dictionary of keyword, value arguments, populates and returns
    a string containing newline-delimited Intex Wraper API arguments

    Args:
        KVdict:  A dictionary object containing Wrapper keyword, value argument pairs

    Returns:
        KVargstring:  A newline-delimited Wrapper keyword=value argument string
    """

    if isinstance(KVdict, dict):
        KVargstring = "\n".join(["%s=%s" % i for i in KVdict.items()]) + "\n"
    else:
        KVargstring = ""

    return KVargstring


class IntexWrapException(Exception):
    """IntexWrapException:  Basic exception raised upon error using the Intex Wrapper API"""

    def __init__(self, *args, **kwargs):
        Exception.__init__(self, *args, **kwargs)


class IntexWrapParseException(IntexWrapException):
    """IntexWrapParseException:  Exception raised upon detection of a syntax or other such error
    within the deal data library files read by the Intex Wrapper API
    """

    def __init__(self, *args, **kwargs):
        IntexWrapException.__init__(self, *args, **kwargs)


class IntexWrapReinitException(IntexWrapException):
    """IntexWrapReinitException:  Exception raised upon detection of an error invalidating the instance
    of the Intex Wrapper API.  The instance must not be used afterward.
    """

    def __init__(self, *args, **kwargs):
        IntexWrapException.__init__(self, *args, **kwargs)


class IntexWrapReloadException(IntexWrapException):
    """IntexWrapReloadException:  Exception raised upon detection of an error invalidating the consistency
    of the deal parsed into the instance of the Intex Wrapper API.  Requires the deal to be re-loaded.
    """

    def __init__(self, *args, **kwargs):
        IntexWrapException.__init__(self, *args, **kwargs)


class IntexWrap:
    """A Python wrapper for the Intex Wrapper API library"""

    def _error_requires_reload(self):
        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_error_requires_reload(
            byref(self._wHandle), byref(self._wDataOut), byref(self._wErrOut)
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        WCMOarg_DataOut_Dict = KeyValDict(
            _get_WCMOarg_from__warg(byref(self._wDataOut))
        )
        if (
            "ERROR_REQUIRES_RELOAD" in WCMOarg_DataOut_Dict
            and WCMOarg_DataOut_Dict["ERROR_REQUIRES_RELOAD"] == "1"
        ):
            return True
        return False

    def _error_requires_reinit(self):
        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_error_requires_reload(
            byref(self._wHandle), byref(self._wDataOut), byref(self._wErrOut)
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        WCMOarg_DataOut_Dict = KeyValDict(
            _get_WCMOarg_from__warg(byref(self._wDataOut))
        )
        if (
            "ERROR_REQUIRES_REINIT" in WCMOarg_DataOut_Dict
            and WCMOarg_DataOut_Dict["ERROR_REQUIRES_REINIT"] == "1"
        ):
            return True
        return False

    def _alloc_wargs(self):
        self._wHandle = c_char_p()
        _wcmoarg_alloc(byref(self._wHandle))
        self._wUser = c_char_p()
        _wcmoarg_alloc(byref(self._wUser))
        self._wDeal = c_char_p()
        _wcmoarg_alloc(byref(self._wDeal))
        self._wOptions = c_char_p()
        _wcmoarg_alloc(byref(self._wOptions))
        self._wCashflow = c_char_p()
        _wcmoarg_alloc(byref(self._wCashflow))
        self._wLoanscen = c_char_p()
        _wcmoarg_alloc(byref(self._wLoanscen))
        self._wPropscen = c_char_p()
        _wcmoarg_alloc(byref(self._wPropscen))
        self._wStats = c_char_p()
        _wcmoarg_alloc(byref(self._wStats))
        self._wUnused1 = c_char_p()
        _wcmoarg_alloc(byref(self._wUnused1))
        self._wUnused2 = c_char_p()
        _wcmoarg_alloc(byref(self._wUnused2))
        self._wDataIn = c_char_p()
        _wcmoarg_alloc(byref(self._wDataIn))
        self._wDataOut = c_char_p()
        _wcmoarg_alloc(byref(self._wDataOut))
        self._wErrOut = c_char_p()
        _wcmoarg_alloc(byref(self._wErrOut))

    def _free_wargs(self):
        if self._wHandle:
            _wcmoarg_free(byref(self._wHandle))
            self._wHandle = None
        if self._wUser:
            _wcmoarg_free(byref(self._wUser))
            self._wUser = None
        if self._wDeal:
            _wcmoarg_free(byref(self._wDeal))
            self._wDeal = None
        if self._wOptions:
            _wcmoarg_free(byref(self._wOptions))
            self._wOptions = None
        if self._wCashflow:
            _wcmoarg_free(byref(self._wCashflow))
            self._wCashflow = None
        if self._wLoanscen:
            _wcmoarg_free(byref(self._wLoanscen))
            self._wLoanscen = None
        if self._wPropscen:
            _wcmoarg_free(byref(self._wPropscen))
            self._wPropscen = None
        if self._wStats:
            _wcmoarg_free(byref(self._wStats))
            self._wStats = None
        if self._wUnused1:
            _wcmoarg_free(byref(self._wUnused1))
            self._wUnused1 = None
        if self._wUnused2:
            _wcmoarg_free(byref(self._wUnused2))
            self._wUnused2 = None
        if self._wDataIn:
            _wcmoarg_free(byref(self._wDataIn))
            self._wDataIn = None
        if self._wDataOut:
            _wcmoarg_free(byref(self._wDataOut))
            self._wDataOut = None
        if self._wErrOut:
            _wcmoarg_free(byref(self._wErrOut))
            self._wErrOut = None

    def __init__(self, *args):
        """IntexWrap:  Generate a new instance of an IntexWrap object. May be called with one
        of two valid argument sets.

        Args (option 1):
            None

        Args (option 2):
            WCMOarg_Handle:
            WCMOarg_User:

        Returns:
            A new instance of an IntexWrap object

        Raises:
            IntexWrapException
        """

        self._InstanceHandle = None

        if len(args) == 0:
            WCMOarg_Handle = "KEYVAL_DELIM_ASCII=10\nCONVERT_NON_UTF8=1\n"
            WCMOarg_User = None
        elif len(args) == 2:
            if isinstance(args[0], dict):
                WCMOarg_Handle = (
                    KeyValArgString(args[0])
                    + "\nKEYVAL_DELIM_ASCII=10\nCONVERT_NON_UTF8=1\n"
                )
            else:
                WCMOarg_Handle = (
                    args[0] + "\nKEYVAL_DELIM_ASCII=10\nCONVERT_NON_UTF8=1\n"
                )
            if isinstance(args[1], dict):
                WCMOarg_User = KeyValArgString(args[1])
            else:
                WCMOarg_User = args[1]
        else:
            raise IntexWrapException(
                "Invalid number of arguments passed to IntexWrap initializer"
            )

        self._alloc_wargs()

        _set_WCMOarg_to__warg(WCMOarg_Handle, byref(self._wHandle))
        _set_WCMOarg_to__warg(WCMOarg_User, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_init(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        kvdict = KeyValDict(_get_WCMOarg_from__warg(byref(self._wDataOut)))
        self._InstanceHandle = "INSTANCE_HANDLE=" + kvdict["INSTANCE_HANDLE"] + "\n"

    def __del__(self):
        if self._InstanceHandle:
            _set_WCMOarg_to__warg(
                self._InstanceHandle + "EXIT_ONLY_INSTANCE=1\n", byref(self._wHandle)
            )
            _set_WCMOarg_to__warg(None, byref(self._wUser))
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            _set_WCMOarg_to__warg(None, byref(self._wErrOut))

            retval = _wcmo_exit(
                byref(self._wHandle),
                byref(self._wUser),
                byref(self._wDataOut),
                byref(self._wErrOut),
            )

        self._free_wargs()
        self._InstanceHandle = None

    def exit(self):
        """IntexWrap.exit():  Calls the Intex Wrapper API function wcmo_exit().
        Releases the native memory associated with the Wrapper instance

        Args:
            None

        Returns:
            None

        Raises:
            IntexWrapException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(
            self._InstanceHandle + "EXIT_ONLY_INSTANCE=1\n", byref(self._wHandle)
        )
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_exit(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wHandle))
            _set_WCMOarg_to__warg(None, byref(self._wUser))
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            raise IntexWrapException(ErrMsg)

        self._free_wargs()
        self._InstanceHandle = None

    def deal(self, WCMOarg_Options, WCMOarg_Deal):
        """IntexWrap.deal():  Calls the Intex Wrapper API function wcmo_deal()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Deal:     Python str or dict object containing WCMOarg_Deal keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapParseException; IntexWrapReinitException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        if isinstance(WCMOarg_Deal, dict):
            WCMOarg_Deal = KeyValArgString(WCMOarg_Deal)
        _set_WCMOarg_to__warg(WCMOarg_Deal, byref(self._wDeal))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_deal(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDeal),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            else:
                raise IntexWrapParseException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def cashflow(
        self,
        WCMOarg_Options,
        WCMOarg_Unused1,
        WCMOarg_Cashflow,
        WCMOarg_Loanscen,
        WCMOarg_Propscen,
    ):
        """IntexWrap.cashflow():  Calls the Intex Wrapper API function wcmo_cashflow()

        Args:
            WCMOarg_Options:    Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:    Ignored.  Pass None
            WCMOarg_Cashflow:   Python str or dict object containing WCMOarg_Cashflow keywords and values
            WCMOarg_Loanscen:   Python str or dict object containing WCMOarg_Loanscen keywords and values
            WCMOarg_Propscen:   Python str or dict object containing WCMOarg_Propscen keywords and values

        Returns:
            WCMOarg_DataOut:    Python str object containing newline-delimited keyword=value pairs.
                                Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        if isinstance(WCMOarg_Cashflow, dict):
            WCMOarg_Cashflow = KeyValArgString(WCMOarg_Cashflow)
        _set_WCMOarg_to__warg(WCMOarg_Cashflow, byref(self._wCashflow))
        if isinstance(WCMOarg_Loanscen, dict):
            WCMOarg_Loanscen = KeyValArgString(WCMOarg_Loanscen)
        _set_WCMOarg_to__warg(WCMOarg_Loanscen, byref(self._wLoanscen))
        if isinstance(WCMOarg_Propscen, dict):
            WCMOarg_Propscen = KeyValArgString(WCMOarg_Propscen)
        _set_WCMOarg_to__warg(WCMOarg_Propscen, byref(self._wPropscen))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_cashflow(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wCashflow),
            byref(self._wLoanscen),
            byref(self._wPropscen),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wCashflow))
        _set_WCMOarg_to__warg(None, byref(self._wLoanscen))
        _set_WCMOarg_to__warg(None, byref(self._wPropscen))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def stats(self, WCMOarg_Options, WCMOarg_Unused1, WCMOarg_Cashflow, WCMOarg_Stats):
        """IntexWrap.stats():  Calls the Intex Wrapper API function wcmo_stats()

        Args:
            WCMOarg_Options:    Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:    Ignored.  Pass None
            WCMOarg_Cashflow:   Python str or dict object containing WCMOarg_Cashflow keywords and values
            WCMOarg_Stats:      Python str or dict object containing WCMOarg_Stats keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        if isinstance(WCMOarg_Cashflow, dict):
            WCMOarg_Cashflow = KeyValArgString(WCMOarg_Cashflow)
        _set_WCMOarg_to__warg(WCMOarg_Cashflow, byref(self._wCashflow))
        if isinstance(WCMOarg_Stats, dict):
            WCMOarg_Stats = KeyValArgString(WCMOarg_Stats)
        _set_WCMOarg_to__warg(WCMOarg_Stats, byref(self._wStats))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_stats(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wCashflow),
            byref(self._wStats),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wCashflow))
        _set_WCMOarg_to__warg(None, byref(self._wStats))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def collat(self, WCMOarg_Options, WCMOarg_Deal):
        """IntexWrap.collat():  Calls the Intex Wrapper API function wcmo_collat()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Deal:     Python str or dict object containing WCMOarg_Deal keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        if isinstance(WCMOarg_Deal, dict):
            WCMOarg_Deal = KeyValArgString(WCMOarg_Deal)
        _set_WCMOarg_to__warg(WCMOarg_Deal, byref(self._wDeal))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_collat(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDeal),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDeal))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def abs_summary(self, WCMOarg_Options, WCMOarg_Deal):
        """IntexWrap.abs_summary():  Calls the Intex Wrapper API function wcmo_abs_summary()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Deal:     Python str or dict object containing WCMOarg_Deal keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        if isinstance(WCMOarg_Deal, dict):
            WCMOarg_Deal = KeyValArgString(WCMOarg_Deal)
        _set_WCMOarg_to__warg(WCMOarg_Deal, byref(self._wDeal))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_abs_summary(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDeal),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDeal))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def propinfo(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.propinfo():  Calls the Intex Wrapper API function wcmo_propinfo()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused:   Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_propinfo(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def remittance(self, WCMOarg_Options, WCMOarg_Deal):
        """IntexWrap.remittance():  Calls the Intex Wrapper API function wcmo_remittance()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Deal:     Python str or dict object containing WCMOarg_Deal keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        if isinstance(WCMOarg_Deal, dict):
            WCMOarg_Deal = KeyValArgString(WCMOarg_Deal)
        _set_WCMOarg_to__warg(WCMOarg_Deal, byref(self._wDeal))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_remittance(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDeal),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDeal))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def database_tree(self, WCMOarg_DataIn, WCMOarg_Options):
        """IntexWrap.database_tree():  Calls the Intex Wrapper API function wcmo_database_tree()

        Args:
            WCMOarg_DataIn:  Python str or dict object containing WCMOarg_DataIn keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        if isinstance(WCMOarg_DataIn, dict):
            WCMOarg_DataIn = KeyValArgString(WCMOarg_DataIn)
        _set_WCMOarg_to__warg(WCMOarg_DataIn, byref(self._wDataIn))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_database_tree(
            byref(self._wHandle),
            byref(self._wDataIn),
            byref(self._wOptions),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wDataIn))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def business_date_adj(self, WCMOarg_Options):
        """IntexWrap.business_date_adj():  Calls the Intex Wrapper API function wcmo_business_date_adj()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_business_date_adj(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def dbstatus(self, WCMOarg_DataIn):
        """IntexWrap.dbstatus():  Calls the Intex Wrapper API function wcmo_dbstatus()

        Args:
            WCMOarg_DataIn:  Python str or dict object containing WCMOarg_DataIn keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        if isinstance(WCMOarg_DataIn, dict):
            WCMOarg_DataIn = KeyValArgString(WCMOarg_DataIn)
        _set_WCMOarg_to__warg(WCMOarg_DataIn, byref(self._wDataIn))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_dbstatus(
            byref(self._wHandle),
            byref(self._wDataIn),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wDataIn))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def portf_setup(self, WCMOarg_Options, WCMOarg_Deal):
        """IntexWrap.portf_setup():  Calls the Intex Wrapper API function wcmo_portf_setup()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Deal:     Python str or dict object containing WCMOarg_Deal keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        if isinstance(WCMOarg_Deal, dict):
            WCMOarg_Deal = KeyValArgString(WCMOarg_Deal)
        _set_WCMOarg_to__warg(WCMOarg_Deal, byref(self._wDeal))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_portf_setup(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDeal),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDeal))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def callpro(self, WCMOarg_Options, WCMOarg_Unused1, WCMOarg_Unused2):
        """IntexWrap.callpro():  Calls the Intex Wrapper API function wcmo_callpro()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None
            WCMOarg_Unused2:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDeal))
        _set_WCMOarg_to__warg(None, byref(self._wCashflow))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_callpro(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDeal),
            byref(self._wCashflow),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDeal))
        _set_WCMOarg_to__warg(None, byref(self._wCashflow))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def history(self, WCMOarg_Options, WCMOarg_Deal):
        """IntexWrap.history():  Calls the Intex Wrapper API function wcmo_history()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Deal:     Python str or dict object containing WCMOarg_Deal keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        if isinstance(WCMOarg_Deal, dict):
            WCMOarg_Deal = KeyValArgString(WCMOarg_Deal)
        _set_WCMOarg_to__warg(WCMOarg_Deal, byref(self._wDeal))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_history(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDeal),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDeal))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def portf_strat_entry(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.portf_strat_entry():  Calls the Intex Wrapper API function wcmo_portf_strat_entry()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_portf_strat_entry(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def trigseries(self, WCMOarg_Options, WCMOarg_Unused1, WCMOarg_Unused2):
        """IntexWrap.trigseries():  Calls the Intex Wrapper API function wcmo_trigseries()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None
            WCMOarg_Unused2:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wUnused2))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_trigseries(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wUnused2),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wUnused2))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def collcf(self, WCMOarg_Options, WCMOarg_Unused1, WCMOarg_Unused2):
        """IntexWrap.collcf():  Calls the Intex Wrapper API function wcmo_collcf()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None
            WCMOarg_Unused2:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wUnused2))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_collcf(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wUnused2),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wUnused2))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def moodybet(
        self,
        WCMOarg_Options,
        WCMOarg_Unused1,
        WCMOarg_Cashflow,
        WCMOarg_Loanscen,
        WCMOarg_Propscen,
    ):
        """IntexWrap.moodybet():  Calls the Intex Wrapper API function wcmo_moodybet()

        Args:
            WCMOarg_Options:   Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:   Ignored.  Pass None
            WCMOarg_Cashflow:  Python str or dict object containing WCMOarg_Cashflow keywords and values
            WCMOarg_Loanscen:  Python str or dict object containing WCMOarg_Loanscen keywords and values
            WCMOarg_Propscen:  Python str or dict object containing WCMOarg_Propscen keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        if isinstance(WCMOarg_Cashflow, dict):
            WCMOarg_Cashflow = KeyValArgString(WCMOarg_Cashflow)
        _set_WCMOarg_to__warg(WCMOarg_Cashflow, byref(self._wCashflow))
        if isinstance(WCMOarg_Loanscen, dict):
            WCMOarg_Loanscen = KeyValArgString(WCMOarg_Loanscen)
        _set_WCMOarg_to__warg(WCMOarg_Loanscen, byref(self._wLoanscen))
        if isinstance(WCMOarg_Propscen, dict):
            WCMOarg_Propscen = KeyValArgString(WCMOarg_Propscen)
        _set_WCMOarg_to__warg(WCMOarg_Propscen, byref(self._wPropscen))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_moodybet(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wCashflow),
            byref(self._wLoanscen),
            byref(self._wPropscen),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wCashflow))
        _set_WCMOarg_to__warg(None, byref(self._wLoanscen))
        _set_WCMOarg_to__warg(None, byref(self._wPropscen))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def vector_product(self, WCMOarg_DataIn):
        """IntexWrap.vector_product():  Calls the Intex Wrapper API function wcmo_vector_product()

        Args:
            WCMOarg_DataIn:  Python str or dict object containing WCMOarg_DataIn keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        if isinstance(WCMOarg_DataIn, dict):
            WCMOarg_DataIn = KeyValArgString(WCMOarg_DataIn)
        _set_WCMOarg_to__warg(WCMOarg_DataIn, byref(self._wDataIn))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_vector_product(
            byref(self._wHandle),
            byref(self._wDataIn),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wDataIn))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def collars(self, WCMOarg_Options, WCMOarg_Cashflow):
        """IntexWrap.collars():  Calls the Intex Wrapper API function wcmo_collars()

        Args:
            WCMOarg_Options:   Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Cashflow:  Python str or dict object containing WCMOarg_Cashflow keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        if isinstance(WCMOarg_Cashflow, dict):
            WCMOarg_Cashflow = KeyValArgString(WCMOarg_Cashflow)
        _set_WCMOarg_to__warg(WCMOarg_Cashflow, byref(self._wCashflow))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_collars(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wCashflow),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wCashflow))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def interpolate(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.interpolate():  Calls the Intex Wrapper API function wcmo_interpolate()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_interpolate(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def extinfo(self, WCMOarg_DataIn):
        """IntexWrap.extinfo():  Calls the Intex Wrapper API function wcmo_extinfo()

        Args:
            WCMOarg_DataIn:   Python str or dict object containing WCMOarg_DataIn keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        if isinstance(WCMOarg_DataIn, dict):
            WCMOarg_DataIn = KeyValArgString(WCMOarg_DataIn)
        _set_WCMOarg_to__warg(WCMOarg_DataIn, byref(self._wDataIn))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_extinfo(
            byref(self._wHandle),
            byref(self._wDataIn),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wDataIn))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def deal_info(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.deal_info():  Calls the Intex Wrapper API function wcmo_deal_info()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_deal_info(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def create_cdu(
        self,
        WCMOarg_Options,
        WCMOarg_Cashflow,
        WCMOarg_Loanscen,
        WCMOarg_Propscen,
        WCMOarg_DataIn,
    ):
        """IntexWrap.create_cdu():  Calls the Intex Wrapper API function wcmo_create_cdu()

        Args:
            WCMOarg_Options:   Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Cashflow:  Python str or dict object containing WCMOarg_Cashflow keywords and values
            WCMOarg_Loanscen:  Python str or dict object containing WCMOarg_Loanscen keywords and values
            WCMOarg_Propscen:  Python str or dict object containing WCMOarg_Propscen keywords and values
            WCMOarg_DataIn:    Python str or dict object containing WCMOarg_DataIn keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        if isinstance(WCMOarg_Cashflow, dict):
            WCMOarg_Cashflow = KeyValArgString(WCMOarg_Cashflow)
        _set_WCMOarg_to__warg(WCMOarg_Cashflow, byref(self._wCashflow))
        if isinstance(WCMOarg_Loanscen, dict):
            WCMOarg_Loanscen = KeyValArgString(WCMOarg_Loanscen)
        _set_WCMOarg_to__warg(WCMOarg_Loanscen, byref(self._wLoanscen))
        if isinstance(WCMOarg_Propscen, dict):
            WCMOarg_Propscen = KeyValArgString(WCMOarg_Propscen)
        _set_WCMOarg_to__warg(WCMOarg_Propscen, byref(self._wPropscen))
        if isinstance(WCMOarg_DataIn, dict):
            WCMOarg_DataIn = KeyValArgString(WCMOarg_DataIn)
        _set_WCMOarg_to__warg(WCMOarg_DataIn, byref(self._wDataIn))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_create_cdu(
            byref(self._wHandle),
            byref(self._wOptions),
            byref(self._wCashflow),
            byref(self._wLoanscen),
            byref(self._wPropscen),
            byref(self._wDataIn),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wCashflow))
        _set_WCMOarg_to__warg(None, byref(self._wLoanscen))
        _set_WCMOarg_to__warg(None, byref(self._wPropscen))
        _set_WCMOarg_to__warg(None, byref(self._wDataIn))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def set_script(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.set_script():  Calls the Intex Wrapper API function wcmo_set_script()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_set_script(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def convert_rate_curve(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.convert_rate_curve():  Calls the Intex Wrapper API function wcmo_convert_rate_curve()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_convert_rate_curve(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def breakeven_analysis(
        self,
        WCMOarg_Options,
        WCMOarg_Unused1,
        WCMOarg_Cashflow,
        WCMOarg_Loanscen,
        WCMOarg_Propscen,
    ):
        """IntexWrap.breakeven_analysis():  Calls the Intex Wrapper API function wcmo_breakeven_analysis()

        Args:
            WCMOarg_Options:   Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:   Ignored.  Pass None
            WCMOarg_Cashflow:  Python str or dict object containing WCMOarg_Cashflow keywords and values
            WCMOarg_Loanscen:  Python str or dict object containing WCMOarg_Loanscen keywords and values
            WCMOarg_Propscen:  Python str or dict object containing WCMOarg_Propscen keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        if isinstance(WCMOarg_Cashflow, dict):
            WCMOarg_Cashflow = KeyValArgString(WCMOarg_Cashflow)
        _set_WCMOarg_to__warg(WCMOarg_Cashflow, byref(self._wCashflow))
        if isinstance(WCMOarg_Loanscen, dict):
            WCMOarg_Loanscen = KeyValArgString(WCMOarg_Loanscen)
        _set_WCMOarg_to__warg(WCMOarg_Loanscen, byref(self._wLoanscen))
        if isinstance(WCMOarg_Propscen, dict):
            WCMOarg_Propscen = KeyValArgString(WCMOarg_Propscen)
        _set_WCMOarg_to__warg(WCMOarg_Propscen, byref(self._wPropscen))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_breakeven_analysis(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wCashflow),
            byref(self._wLoanscen),
            byref(self._wPropscen),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wCashflow))
        _set_WCMOarg_to__warg(None, byref(self._wLoanscen))
        _set_WCMOarg_to__warg(None, byref(self._wPropscen))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def uexp_catalog(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.uexp_catalog():  Calls the Intex Wrapper API function wcmo_uexp_catalog()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_uexp_catalog(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def vector_elements(self, WCMOarg_DataIn):
        """IntexWrap.vector_elements():  Calls the Intex Wrapper API function wcmo_vector_elements()

        Args:
            WCMOarg_DataIn:  Python str or dict object containing WCMOarg_DataIn keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        if isinstance(WCMOarg_DataIn, dict):
            WCMOarg_DataIn = KeyValArgString(WCMOarg_DataIn)
        _set_WCMOarg_to__warg(WCMOarg_DataIn, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_vector_elements(
            byref(self._wHandle),
            byref(self._wDataIn),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def set_asset_data(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.set_asset_data():  Calls the Intex Wrapper API function wcmo_set_asset_data()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_set_asset_data(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def dll_version(self, WCMOarg_DataIn=None):
        """IntexWrap.dll_version():  Calls the Intex Wrapper API function wcmo_dll_version().  May be called in two modes:

        Args (mode 1):
            None

        Returns (mode 1):
            WCMOarg_DataOut: Python string identifying the DLL version number of the Intex Wrapper API.
                             Use KeyValDict() on the return string to parse output from a dict object

        Args (mode 2):
            WCMOarg_DataIn:  Python string with a version number to test DLL version against (e.g., "3.4.60.3")

        Returns (mode 2):
            Boolean True/False depending on whether DLL version is lower or equal to the requested version

        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(WCMOarg_DataIn, byref(self._wDataIn))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))

        retval = _wcmo_dll_version(byref(self._wDataIn), byref(self._wDataOut))

        if WCMOarg_DataIn is not None:
            _set_WCMOarg_to__warg(None, byref(self._wDataIn))
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            if retval == 0:
                return False
            return True
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def collat_split(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.collat_split():  Calls the Intex Wrapper API function wcmo_collat_split()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_collat_split(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def ucollat_subset_catalog(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.ucollat_subset_catalog():  Calls the Intex Wrapper API function wcmo_ucollat_subset_catalog()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_ucollat_subset_catalog(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def uentity_catalog(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.uentity_catalog():  Calls the Intex Wrapper API function wcmo_uentity_catalog()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_uentity_catalog(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def get_cf_events(self, WCMOarg_Options):
        """IntexWrap.get_cf_events():  Calls the Intex Wrapper API function wcmo_get_cf_events()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_get_cf_events(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def fitch_breakevens(
        self,
        WCMOarg_Options,
        WCMOarg_Unused1,
        WCMOarg_Cashflow,
        WCMOarg_Loanscen,
        WCMOarg_Propscen,
    ):
        """IntexWrap.fitch_breakevens():  Calls the Intex Wrapper API function wcmo_fitch_breakevens()

        Args:
            WCMOarg_Options:   Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:   Ignored.  Pass None
            WCMOarg_Cashflow:  Python str or dict object containing WCMOarg_Cashflow keywords and values
            WCMOarg_Loanscen:  Python str or dict object containing WCMOarg_Loanscen keywords and values
            WCMOarg_Propscen:  Python str or dict object containing WCMOarg_Propscen keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        if isinstance(WCMOarg_Cashflow, dict):
            WCMOarg_Cashflow = KeyValArgString(WCMOarg_Cashflow)
        _set_WCMOarg_to__warg(WCMOarg_Cashflow, byref(self._wCashflow))
        if isinstance(WCMOarg_Loanscen, dict):
            WCMOarg_Loanscen = KeyValArgString(WCMOarg_Loanscen)
        _set_WCMOarg_to__warg(WCMOarg_Loanscen, byref(self._wLoanscen))
        if isinstance(WCMOarg_Propscen, dict):
            WCMOarg_Propscen = KeyValArgString(WCMOarg_Propscen)
        _set_WCMOarg_to__warg(WCMOarg_Propscen, byref(self._wPropscen))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_fitch_breakevens(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wCashflow),
            byref(self._wLoanscen),
            byref(self._wPropscen),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wCashflow))
        _set_WCMOarg_to__warg(None, byref(self._wLoanscen))
        _set_WCMOarg_to__warg(None, byref(self._wPropscen))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def modify_deal_collat(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.modify_deal_collat():  Calls the Intex Wrapper API function wcmo_modify_deal_collat()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_modify_deal_collat(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def replace_collat(self, WCMOarg_Options, WCMOarg_Unused1):
        """IntexWrap.replace_collat():  Calls the Intex Wrapper API function wcmo_replace_collat()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_Unused1:  Ignored.  Pass None

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_replace_collat(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wUnused1),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wUnused1))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def waterfall_report(self, WCMOarg_Options):
        """IntexWrap.waterfall_report():  Calls the Intex Wrapper API function wcmo_waterfall_report()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_waterfall_report(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def cluster_collat(self, WCMOarg_Options):
        """IntexWrap.cluster_collat():  Calls the Intex Wrapper API function wcmo_cluster_collat()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_cluster_collat(
            byref(self._wHandle),
            byref(self._wUser),
            byref(self._wOptions),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wUser))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def socket(self, WCMOarg_Options):
        """IntexWrap.socket():  Calls the Intex Wrapper API function wcmo_socket()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_socket(
            byref(self._wHandle),
            byref(self._wOptions),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def interrogate_thread(self, WCMOarg_Options):
        """IntexWrap.interrogate_thread():  Calls the Intex Wrapper API function wcmo_interrogate_thread()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        if isinstance(WCMOarg_Options, dict):
            WCMOarg_Options = KeyValArgString(WCMOarg_Options)
        _set_WCMOarg_to__warg(WCMOarg_Options, byref(self._wOptions))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_interrogate_thread(
            byref(self._wHandle),
            byref(self._wOptions),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wOptions))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def idsys(self, WCMOarg_DataIn):
        """IntexWrap.idsys():  Calls the Intex Wrapper API function wcmo_idsys()

        Args:
            WCMOarg_DataIn:   Python str or dict object containing WCMOarg_DataIn keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object

        Raises:
            IntexWrapException; IntexWrapReinitException; IntexWrapReloadException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        _set_WCMOarg_to__warg(self._InstanceHandle, byref(self._wHandle))
        if isinstance(WCMOarg_DataIn, dict):
            WCMOarg_DataIn = KeyValArgString(WCMOarg_DataIn)
        _set_WCMOarg_to__warg(WCMOarg_DataIn, byref(self._wDataIn))
        _set_WCMOarg_to__warg(None, byref(self._wDataOut))
        _set_WCMOarg_to__warg(None, byref(self._wErrOut))

        retval = _wcmo_idsys(
            byref(self._wHandle),
            byref(self._wDataIn),
            byref(self._wDataOut),
            byref(self._wErrOut),
        )

        _set_WCMOarg_to__warg(None, byref(self._wHandle))
        _set_WCMOarg_to__warg(None, byref(self._wDataIn))

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            ErrMsg = _get_WCMOarg_from__warg(byref(self._wErrOut))
            if self._error_requires_reinit():
                raise IntexWrapReinitException(ErrMsg)
            elif self._error_requires_reload():
                raise IntexWrapReloadException(ErrMsg)
            raise IntexWrapException(ErrMsg)

        _set_WCMOarg_to__warg(None, byref(self._wErrOut))
        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def daycount(self, WCMOarg_Options, recent_date, older_date):
        """IntexWrap.daycount():  Calls the Intex Wrapper API function wcmo_daycount()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            recent_date:      The recent date
            older_date:       The older date

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        return _wcmo_daycount(
            byref(self._wHandle), byref(self._wOptions), recent_date, older_date
        )

    def price_format(self, WCMOarg_Options, WCMOarg_DataIn, WCMOarg_DataOut):
        """IntexWrap.price_format():  Calls the Intex Wrapper API function wcmo_price_format()

        Args:
            WCMOarg_Options:  Python str or dict object containing WCMOarg_Options keywords and values
            WCMOarg_DataIn:   Python str or dict object containing WCMOarg_DataIn keywords and values

        Returns:
            WCMOarg_DataOut:  Python str object containing newline-delimited keyword=value pairs.
                              Use KeyValDict() on the return string to parse output from a dict object
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        retval = _wcmo_price_format(
            byref(self._wOptions), byref(self._wDataIn), byref(self._wDataOut)
        )

        if retval != 0:
            _set_WCMOarg_to__warg(None, byref(self._wDataOut))
            raise IntexWrapException("Error formatting price.")

        return _get_WCMOarg_from__warg(byref(self._wDataOut))

    def YyyyMmDd_diff(self, recent_date, older_date, cal_30360):
        """IntexWrap.YyyyMmDd_diff():  Calls the Intex Wrapper API function wcmo_YyyyMmDd_diff()

        Args:
            recent_date:  The recent date
            older_date:   The older date
            cal_30360:    0/1 - whether to use a 30360 calendar basis

        Returns:
            Integer number of days difference

        Raises:
            IntexWrapReinitException
        """

        if not self._InstanceHandle:
            raise IntexWrapReinitException(
                "Instance of IntexWrap class used after IntexWrap.exit() has been called."
            )

        return _wcmo_YyyyMmDd_diff(recent_date, older_date, cal_30360)
