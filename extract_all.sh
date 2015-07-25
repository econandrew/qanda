for f in transcripts/*.htm
do
	#echo $f
  python3 extract_qanda.py $f
done
