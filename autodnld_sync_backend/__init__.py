import logging
import subprocess
import azure.functions as func
import os
import sys
import traceback


def main(msg: func.QueueMessage) -> None:
    command = msg.get_body().decode("utf-8")
    if command == "data-sync":
        script_dir = os.path.join(
            os.environ["PROJECT_DIR"], "autodnld_sync_backend", "autodnld", "scripts"
        )
        try:
            result_perl_script = subprocess.check_output(
                ["perl", os.path.join(script_dir, "autodnld.pl")], cwd=script_dir
            )

        except subprocess.CalledProcessError as e:
            logging.error("Autodnld subprocess script failed with error" + e)

        logging.info("Autodnld executed successfully")

    else:
        logging.info("Enter correct command to start the auto sync backend process")
