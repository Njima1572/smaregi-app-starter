#!/bin/bash
# 使い方：　./deploy.sh ENV_NAME
# ENV_NAMEは qaかprod (例)：./deploy.sh qa

##################　共通モジュール　ここから　##################
# 引数チェック
if [ $# != 1 ]; then
    echo "引数を指定して下さい。"
    echo "- 使い方：./deploy.sh ENV_NAME"
    echo "- ENV_NAMEは qaかprodを指定して下さい。"
    echo "- (例)：./deploy.sh qa"
    exit 1
elif [ $1 != "prod" ] && [ $1 != "qa" ];then
    echo "引数の値に誤りがあります。qaかprodで指定して下さい"
    echo "(例)：./deploy.sh qa"
    exit 1
else
    DEPLOY_ENV=$1
    echo "[${DEPLOY_ENV}]環境にデプロイします"
fi

# 設定ファイル読み込み
SCRIPT_DIR=$(cd $(dirname $0); pwd)
CRED_DIR="${SCRIPT_DIR}/../_init/credentials"
. $CRED_DIR/secrets.txt

# Project IDをセット（セットされていても事故を防ぐためセット）
gcloud config set project $PROJECT_ID
echo "PROJECT ID is ${PROJECT_ID}"

# デプロイログと通知
function log_and_notify() {
    echo `date`" [${DEPLOY_ENV}] ${CLOUD_FUNC_NAME}/${CLOUD_FUNC_ENTRYPOINT} in ${PROJECT_ID}" >> ${SCRIPT_DIR}/deploy-log.txt
}

##################　共通モジュール　ここまで　##################

# 関数設定
CLOUD_FUNC_NAME="${DEPLOY_ENV}-contract-webhook"
CLOUD_FUNC_ENTRYPOINT="contract_update_webhook_receiver"
echo "[${DEPLOY_ENV}] Deploy ${CLOUD_FUNC_NAME} func"
echo "[${DEPLOY_ENV}] Entry point is ${CLOUD_FUNC_ENTRYPOINT}"

if [ $DEPLOY_ENV = "qa" ]; then
	gcloud functions deploy $CLOUD_FUNC_NAME \
        --source $SCRIPT_DIR/deploy \
        --set-env-vars env=${DEPLOY_ENV},projectID=${PROJECT_ID}  \
        --entry-point $CLOUD_FUNC_ENTRYPOINT \
        --memory 128mb \
        --runtime python38 --region asia-northeast1 --trigger-http --allow-unauthenticated &&\
    log_and_notify

elif [ $DEPLOY_ENV = "prod" ]; then
	gcloud functions deploy $CLOUD_FUNC_NAME \
        --source $SCRIPT_DIR/deploy \
        --set-env-vars env=${DEPLOY_ENV},projectID=${PROJECT_ID}  \
        --entry-point $CLOUD_FUNC_ENTRYPOINT \
        --memory 128mb \
        --runtime python38 --region asia-northeast1 --trigger-http --allow-unauthenticated &&\
    log_and_notify

else
	echo "エラー　$DEPLOY_ENVがセットされていません"
fi
