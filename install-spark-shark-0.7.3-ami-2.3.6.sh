
cd /home/hadoop/

wget http://spark-project.org/download/spark-0.7.3-prebuilt-hadoop1.tgz
wget http://www.scala-lang.org/files/archive/scala-2.9.3.tgz
wget http://spark-project.org/download/shark-0.7.0-hadoop1-bin.tgz

tar -xvzf scala-2.9.3.tgz
tar -xvzf spark-0.7.3-prebuilt-hadoop1.tgz
tar -xvzf shark-0.7.0-hadoop1-bin.tgz

ln -sf spark-0.7.3 spark
ln -sf shark-0.7.0 shark
ln -sf scala-2.9.3 scala

export SCALA_HOME=/home/hadoop/scala-2.9.3

MASTER=$(grep -i "job.tracker<" /home/hadoop/conf/mapred-site.xml | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
SPACE=$(mount | grep mnt | awk '{print $3"/spark/"}' | xargs | sed 's/ /,/g')

touch /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_MASTER_IP=$MASTER">> /home/hadoop/spark/conf/spark-env.sh
echo "export SCALA_HOME=/home/hadoop/scala-2.9.3" >> /home/hadoop/spark/conf/spark-env.sh
echo "export MASTER=spark://$MASTER:7077" >> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_LIBRARY_PATH=/home/hadoop/native/Linux-amd64-64" >> /home/hadoop/spark/conf/spark-env.sh
echo "export SPARK_JAVA_OPTS=\"-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Dspark.local.dir=$SPACE\"" >> /home/hadoop/spark/conf/spark-env.sh

cp /home/hadoop/lib/gson-* /home/hadoop/spark/lib_managed/jars/
cp /home/hadoop/lib/aws-java-sdk-* /home/hadoop/spark/lib_managed/jars/
cp /home/hadoop/conf/core-site.xml /home/hadoop/spark/conf/
cp /home/hadoop/hadoop-core.jar /home/hadoop/spark/lib_managed/jars/hadoop-core-1.0.3.jar 
cp /home/hadoop/lib/*etrics*  /home/hadoop/spark/lib_managed/jars/

touch /home/hadoop/shark/conf/shark-env.sh
cp /home/hadoop/lib/gson-* /home/hadoop/shark/lib_managed/jars/
cp /home/hadoop/lib/aws-java-sdk-* /home/hadoop/shark/lib_managed/jars/
cp /home/hadoop/conf/core-site.xml /home/hadoop/shark/conf/
cp /home/hadoop/hadoop-core.jar /home/hadoop/shark/lib_managed/jars/hadoop-core-1.0.3.jar
cp /home/hadoop/lib/*etrics*  /home/hadoop/shark/lib_managed/jars/
echo "export HIVE_HOME=/home/hadoop/hive-0.9.0-bin/" >> /home/hadoop/shark/conf/shark-env.sh
echo "export SPARK_HOME=/home/hadoop/spark" >>  /home/hadoop/shark/conf/shark-env.sh
echo "source /home/hadoop/spark/conf/spark-env.sh">>    /home/hadoop/shark/conf/shark-env.sh

grep -Fq '"isMaster":true' /mnt/var/lib/info/instance.json
if [ $? -eq 0 ];
then
        /home/hadoop/spark/bin/start-master.sh
else
        nc -z $MASTER 7077
        while [ $? -eq 1 ];                do
                        echo "Can't connect to the master, sleeping for 20sec"
                        sleep 20
                        nc -z  $MASTER 7077
                done
        echo "Conneting to the master was successful"
        echo "export SPARK_JAVA_OPTS=\"-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Dspark.local.dir=$SPACE\"" >> /home/hadoop/spark/conf/spark-env.sh
	/home/hadoop/spark/bin/spark-daemon.sh start spark.deploy.worker.Worker `hostname` spark://$MASTER:7077 
fi
