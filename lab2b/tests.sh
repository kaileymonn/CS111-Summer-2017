#!/bin/bash
rm -rf lab2b_list.csv lab2_list2.csv

list_threads1=(1 2 4 8 12 16 24)

list_threads3=(1 4 8 12 16)
list_iterations3_1=(1 2 4 8 16)
list_iterations3_2=(10 20 40 80)

list_threads4=(1 2 4 8 12)
sublists=(1 4 8 16)

#lab2b_1.png and lab2b_2.png 
for t in "${list_threads1[@]}"; do
    echo "./lab2_list --iterations=1000 --threads=$t --sync=m"
    ./lab2_list --iterations=1000 --threads=$t --sync=m 1>>lab2b_list.csv

    echo "./lab2_list --iterations=1000 --threads=$t --sync=s"
    ./lab2_list --iterations=1000 --threads=$t --sync=s 1>>lab2b_list.csv
done

#lab2b_3.png
for t in "${list_threads3[@]}"; do
    for i in "${list_iterations3_1[@]}"; do
	echo "./lab2_list --iterations=$i --threads=$t --yield=id"
	./lab2_list --iterations=$i --threads=$t --yield=id --lists=4 1>>lab2_list2.csv
	done

    for i in "${list_iterations3_2[@]}"; do
	echo "./lab2_list --iterations=$i --threads=$t --yield=id --sync=m"
	./lab2_list --iterations=$i --threads=$t --yield=id --lists=4 --sync=m 1>>lab2_list2.csv

	echo "./lab2_list --iterations=$i --threads=$t --yield=id --sync=s"
	./lab2_list --iterations=$i --threads=$t --yield=id --lists=4 --sync=s 1>>lab2_list2.csv
	done
done

#lab2b_4.png and lab2b_5.png
for t in "${list_threads4[@]}"; do
    for l in "${sublists[@]}"; do
	echo "./lab2_list --iterations=1000 --lists=$l --threads=$t --sync=m"
	./lab2_list --iterations=1000 --lists=$l --threads=$t --sync=m 1>>lab2_list2.csv
	
	echo "./lab2_list --iterations=1000 --lists=$l --threads=$t --sync=s"
	./lab2_list --iterations=1000 --lists=$l --threads=$t --sync=s 1>>lab2_list2.csv
	done
done
