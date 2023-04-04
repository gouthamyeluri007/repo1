import traceback
import logging
import sys
import azure.functions as func
import configparser
import os
from wrapper_codes.intex_wrap_functions import data_to_csv, IntexWrapException
import time
import json


def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        dealname = req.params.get("dealname")
        func.HttpResponse.mimetype = "application/json"
        func.HttpResponse.charset = "utf-8"

        config = configparser.ConfigParser()

        with open(
            os.path.join(
                os.environ["PROJECT_DIR"],
                "autodnld_sync_backend",
                "autodnld",
                "scripts",
                "autodnld.ini",
            )
        ) as stream:
            config.read_string("[default]\n" + stream.read())
            config = config["default"]
            cdi_path = config["tgt_cdi_dir"]
            cdu_path = config["tgt_cdu_dir"]
            output_path = config["output_path"]

        if dealname:
            data_to_csv(cdi_path, cdu_path, dealname, output_path)
            logging.info(f"CSV with deal name {dealname} is generated successfully.")
            return func.HttpResponse(
                json.dumps(
                    {
                        "error": None,
                        "message": f"Hello, Trigger function executed successfully and deal {dealname}.csv is generated",
                        "result": {"data": f"/results/{dealname}.csv"},
                    }
                )
            )

    except IntexWrapException as IWException:
        logging.error(
            "Error occured inside intex wrap function codes" + traceback.format_exc()
        )

        return func.HttpResponse(
            json.dumps(
                {
                    "error": traceback.format_exc(),
                    "message": f"Error occured inside intex wrap function codes during {dealname}.csv creation",
                    "result": None,
                }
            )
        )
