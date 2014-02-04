#!/bin/sh 
. /cygdrive/d/dtv/enc/bat/shell/include.sh

#####テンポラリディレクトリ作成#####
if [ ! -d temp ] ; then
	mkdir ./temp
	echo "`date '+%F %T'` [$$] tempディレクトリ作成" >> $LOGFILE 2>&1
fi

######エンコード処理開始
#echo "$1"
######TSファイルチェック処理
echo "`date '+%F %T'` [$$] 【エンコード準備開始】 $1" >> $LOGFILE 2>&1
if [ `echo "$1"|tail -c4` != ".ts" ] ; then
        echo "`date '+%F %T'` [$$] 【処理終了】TSファイルではありません。" >> $LOGFILE 2>&1
        exit
	else echo "`date '+%F %T'` [$$] 【TSファイルチェック】OK " >> $LOGFILE 2>&1
fi


######ファイル名の局名、スペース削除

. /cygdrive/d/dtv/enc/bat/shell/name.sh "$1" >> $LOGFILE 2>&1
TS=`echo "$FILENAME"|sed "s/ //g"`


######ファイルの長さチェックとHD分離処理
######すでにHD分離処理をしていないかチェック
if [ `echo "$1"|tail -c7` != "_HD.ts" ] ; then

	######ファイルの長さをチェックし、クリップボードにコピー
	/cygdrive/d/dtv/enc/sinkusuperlite_130101/SinkuSuperLite.exe /s `cygpath.exe -w $TS`

	######時間をファイル名に追加
	mv $TS "${TS//.ts/}"_`getclip |nkf.exe -w|grep MPEG2-TS|awk '{print $3}'`.ts
	TS="${TS//.ts/}"_`getclip |nkf.exe -w|grep MPEG2-TS|awk '{print $3}'`.ts

	######HD分離処理
	echo "`date '+%F %T'` [$$] HD分離処理 : start" >> $LOGFILE 2>&1
	/cygdrive/d/dtv/enc/TsSplitter\ Ver1.23/TsSplitter.exe -SD -1SEG $TS > /dev/null
	echo "`date '+%F %T'` [$$] HD分離処理 : finish" >> $LOGFILE 2>&1

######すでに処理済みの場合、スキップして変数を処理時と合わせる
	else echo "`date '+%F %T'` [$$] HD分離処理 : skip" >> $LOGFILE 2>&1
	TS=`echo ${TS//_HD.ts/.ts}`
fi


######ドロップ、スクランブル解除漏れチェック
#echo "HD分離処理後のファイル名" ${TS//.ts/_HD.ts}
echo "`date '+%F %T'` [$$] ドロップ、スクランブル解除漏れチェック: start" >> $LOGFILE 2>&1
/cygdrive/d/dtv/enc/tsselect/tsselect.exe "${TS//.ts/_HD.ts}" > ${TS//.ts/_HD.ts.tsselect.log} 2> /dev/null
cat ${TS//.ts/_HD.ts.tsselect.log}|sed "s/^/`date '+%F %T'` [$$] /g" >> $LOGFILE 2>&1

if [ 0 -ne `cat ${TS//.ts/_HD.ts.tsselect.log}|sed "s/ //g"|awk -F , '{print $3}'|grep -v d=0|wc -l` ] ; then 
	######ドロップがあった場合
	echo "`date '+%F %T'` [$$] error : ドロップ有" >> $LOGFILE 2>&1
	mv "${TS//.ts/_HD.ts}" "${TS//.ts/_HDドロップ有.ts}"
	echo "`date '+%F %T'` [$$] ドロップ、スクランブル解除漏れチェック: finish" >> $LOGFILE 2>&1
	elif [ 0 -ne `cat ${TS//.ts/_HD.ts.tsselect.log}|sed "s/ //g"|awk -F , '{print $5}'|grep -v scrambling=0|wc -l` ] ; then
		######スクランブル解除漏れがあった場合
		echo "`date '+%F %T'` [$$] error : スクランブル解除漏れ有" >> $LOGFILE 2>&1
		mv "${TS//.ts/_HD.ts}" "${TS//.ts/_HDスクランブル有.ts}"
		echo "`date '+%F %T'` [$$] ドロップ、スクランブル解除漏れチェック: finish" >> $LOGFILE 2>&1
	else echo "`date '+%F %T'` [$$] ドロップ、スクランブル解除漏れチェック: finish" >> $LOGFILE 2>&1

	######ドロップ、スクランブル解除漏れが無い場合
	echo "`date '+%F %T'` [$$] DGIndex.exe処理 : start"  >> $LOGFILE 2>&1
	#####20120911 追加 出力ファイルをtempへ移動#####
#	/cygdrive/d/dtv/enc/dgmpgdec158/DGIndex.exe -i ${TS//.ts/_HD.ts} -o ${TS//.ts/_HD.ts} -ia 5 -fo 0 -yr 2 -om 1 -minimize -hide -exit > /dev/null
	/cygdrive/d/dtv/enc/dgmpgdec158/DGIndex.exe -i ${TS//.ts/_HD.ts} -o temp/${TS//.ts/_HD.ts} -ia 5 -fo 0 -yr 2 -om 1 -minimize -hide -exit > /dev/null
	mv ${TS//.ts/_HD}.log temp/${TS//.ts/_HD.ts}_DGIndex.log

	echo "`date '+%F %T'` [$$] DGIndex.exe処理 : finish"  >> $LOGFILE 2>&1
	rm -f "$TS" "${TS//.ts/_HD.ts.tsselect.log}"
	echo "`date '+%F %T'` [$$] TSファイルの削除 OK"  >> $LOGFILE 2>&1
fi
echo "`date '+%F %T'` [$$] 【エンコード準備終了】 $1" >> $LOGFILE 2>&1
