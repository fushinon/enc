#!/bin/sh 
. /cygdrive/d/dtv/enc/bat/shell/include.sh
LOGFILE=/cygdrive/d/dtv/log/cmenc.`date +%Y%m`.log

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


AVS=temp/${TS//.ts/_HD.ts}.avs
LOGFILE_2ND=/cygdrive/d/dtv/log/cmenc.`date +%Y%m`.log

######エンコード処理開始
echo "`date '+%F %T'` [$$] 【エンコード準備開始】 $AVS" >> $LOGFILE_2ND 2>&1

######avsファイルチェック
if [ `echo "$AVS"|tail -c5` != ".avs" ] ; then
        echo "`date '+%F %T'` [$$] 【処理終了】avsファイルではありません。" >> $LOGFILE_2ND 2>&1
        exit
        else echo "`date '+%F %T'` [$$] 【avsファイルチェック】OK " >> $LOGFILE_2ND 2>&1
fi

sed -e "s/#TIVTC24P2/TIVTC24P2/" $AVS > ${AVS}_cm.avs


echo "`date '+%F %T'` [$$] 音源ファイル準備 : start"  >> $LOGFILE_2ND 2>&1
/cygdrive/d/dtv/enc/bin/avs2wav.exe ${AVS}_cm.avs ${AVS}.wav
/cygdrive/d/dtv/enc/bin/neroAacEnc.exe -ignorelength -lc -q 0.5 -if ${AVS}.wav -of ${AVS}.m4a
echo "`date '+%F %T'` [$$] 音源ファイル準備 : finish"  >> $LOGFILE_2ND 2>&1

echo "`date '+%F %T'` [$$] H.264エンコード : start"  >> $LOGFILE_2ND 2>&1
/cygdrive/d/dtv/enc/bin/x264.exe ${AVS}_cm.avs --level 4.1 --crf 21 --aq-mode 1 --aq-strength 0.8 --psy-rd 1.0:0.25 --deadzone-inter 8 --deadzone-intra 6 --ipratio 1.6 --pbratio 1.4 --qcomp 0.7 --qpmin 12 --qpmax 35 --qpstep 8 --scenecut 70 --min-keyint 1 --keyint 300 --partitions p8x8,b8x8,i4x4 --8x8dct --bframes 4 --nal-hrd vbr --vbv-maxrate 30000 --vbv-bufsize 24000 --b-adapt 2 --direct auto --me umh --subme 7 --merange 32 --sar 1:1 --threads auto --trellis 1 --deblock -1:-1--no-fast-pskip --no-dct-decimate --psnr --ssim --acodec none --output ${AVS}.temp.mp4
echo "`date '+%F %T'` [$$] H.264エンコード : finish"  >> $LOGFILE_2ND 2>&1

echo "`date '+%F %T'` [$$] mp4結合処理 : start"  >> $LOGFILE_2ND 2>&1
/cygdrive/d/dtv/enc/bin/MP4Box.exe -fps 23.976025 -add ${AVS}.temp.mp4 -add ${AVS}.m4a:lang=jpn:name=Main -new ${AVS}_cm.mp4
echo "`date '+%F %T'` [$$] mp4結合処理 : finish"  >> $LOGFILE_2ND 2>&1

#rm -f ${AVS}.wav ${AVS}.m4a ${AVS}.temp.mp4 ${1%%.avs}.d2v ${1%%.avs}_DGIndex.log ${1%%.avs}.tsselect.log ${1%%.avs}*.aac $AVS
rm -f ${AVS}.wav ${AVS}.m4a ${AVS}.temp.mp4 ${AVS//.avs/.d2v} ${AVS//.avs/}_DGIndex.log ${AVS//.avs/}*.aac $AVS ${AVS}_cm.avs
#rm -f ${AVS}.wav ${AVS}.m4a ${AVS}.temp.mp4 ${AVS}_cm.avs $AVS
echo "`date '+%F %T'` [$$] 一時ファイルの削除 : OK"  >> $LOGFILE_2ND 2>&1
echo "`date '+%F %T'` [$$] 【エンコード準備終了】" >> $LOGFILE_2ND 2>&1

