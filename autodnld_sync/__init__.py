import logging
import json
import os
import azure.functions as func
import traceback, sys


def main(
    req: func.HttpRequest,
    autodnldsyncmsg: func.Out[str],
) -> func.HttpResponse:
    func.HttpResponse.mimetype = "application/json"
    func.HttpResponse.charset = "utf-8"
    logging.info("Autodnld_sync function started processing the request.")
    command = req.params.get("command")

    if command == "data-sync":
        autodnldsyncmsg.set(command)
        logging.info(f"Message {command} passed to the queue")
        return func.HttpResponse(
            json.dumps(
                {
                    "Error": None,
                    "Message": "Autodnld sync trigger function is executed and backend function would be triggered.",
                    "Result": None, 
                }
            ),
            status_code=200,
        )
    else:
        return func.HttpResponse(
            json.dumps(
                {
                    "Error": None,
                    "Message": "Pass a 'data-sync' command in the query string to trigger the backend process.",
                    "Result": None,
                }
            ),
            status_code=400,
        )
