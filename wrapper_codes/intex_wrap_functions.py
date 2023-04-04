import logging
from wrapper_codes.intexwrap import (
    IntexWrap,
    IntexWrapException,
    KeyValDict,
    KeyValArgString,
)
import pandas as pd


def data_to_csv(cdiPath, cduPath, dealName, outputFile):
    wrap1 = IntexWrap()

    # Set up parsing options
    dealOptionDict = {
        "CDI_PATH": cdiPath,
        "CDU_PATH": cduPath,
        "TRADING_ACCURACY_NOT_REQUIRED": "1",
    }
    dealDealArgDict = {
        "DEAL_NAME": dealName,
        "DEAL_MODE": "SEASONED_POOLS",
        "SETTLE_YYYYMMDD": "t+3",
    }
    # Make a call to wcmo_deal to parse a deal into memory
    dealOutArg = wrap1.deal(dealOptionDict, dealDealArgDict)
    dealOutDict = KeyValDict(dealOutArg)
    # Set up Collat call to get Asset Details. The NO_SUMMARY option will explode the collat, but omit Total and Group lines. Other options are 0 and 1.
    dealOptionDict["COLLAT_LIST_EXPLODE"] = "NO_SUMMARY"
    # Make a call to wcmo_collat to retrieve asset level information
    collatOutArg = wrap1.collat(dealOptionDict, dealDealArgDict)
    collatOutDict = KeyValDict(collatOutArg)
    # Retrieve all returned wrapper keywords (REPORT_COLLAT_ITEM_LIST) and their user-friendly names (REPORT_COLLAT_ITEM_NAME)
    itemList = collatOutDict["REPORT_COLLAT_ITEM_LIST"]
    itemListArr = itemList.split("|")
    nameList = collatOutDict["REPORT_COLLAT_ITEM_NAME"]
    nameListArr = nameList.split("|")
    # Retrieve the number of assets and store in output string
    numLoans = collatOutDict["N_LOANS"]
    # Loop over LOAN_INFO items and store in output string
    i = 0
    loan_df = pd.DataFrame()
    for i in range(len(itemListArr) - 1):
        loanInfoKey = "LOAN_INFO[" + itemListArr[i] + "]"
        loanInfo = collatOutDict[loanInfoKey]
        if len(loanInfo) > 0:
            loan_df[nameListArr[i]] = list(loanInfo.split("|")[:-1])
    loan_df.to_csv(outputFile + "/" + dealName + ".csv", index=False)
