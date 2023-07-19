#Copy all riboviria from NCBI taxonomy page.

#parse assembly list
while read line; do 
  x=0;
  x=`grep "$line" assembly_summary_refseq.txt`;
  if [[ $x == "" ]]; then echo $line >> failed.txt;
    echo $line; 
  else 
    awk -v q="$line" '{FS="\t"}{if ($8 == q){print $0}}' assembly_summary_refseq.txt >> shortlist.txt;
  fi;
done < Riboviria.txt

perl modified_kraken2_rsync_from_ncbi.pl shortlist.txt

mkdir source
cd source
wget http://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz

cat library.fna | awk '{if ($0 ~ "^>"){match($0, />kraken:taxid\|([0-9]+)/,a); sub(/kraken:taxid\|/, "", a[0]); print a[0]} else {print $0}}' > temp.faa
mv ../temp.faa viruses/kaiju_db_viruses.faa

 if Kaiju was installed locally
~/csf_mNGS/kaiju/bin/kaiju-makedb -t 4 --index-only -s viruses

