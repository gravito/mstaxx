var1=$(grep 'model name' /proc/cpuinfo | wc -l)
for i in $var1
do
        yes > /dev/null &
done
sleep 10
var2=$(top -b -n2 | grep "Cpu(s)" | awk '{print $2+$4}' | tail -n1)
echo $var2
var3=50
for i in $var1
do
sleep 30
if (( $(echo "$var2 > $var3" | bc -l) )); then
    kubectl scale deployment frontend --replicas=5
else
    echo "CPU Load not spiking"
fi
done
kubectl get pods
sleep 10
killall yes
kubectl scale deployment frontend --replicas=3

