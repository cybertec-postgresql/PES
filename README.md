# PES
Patroni Environment Setup

idea is as follows: suppose we got 3 tabs ... simple executable (statically linked ideally):
consider the following scenario: you start the executable on all three nodes.
on the first one you enter the data ... etcd port, postgres ports, whatever is needed (as little as possible, ideally only network stuff).
then you "broadcast" that to the other nodes you listed. on the other nodes you are not in the "create tab" but in the "receive info tab" ...
the "first node" sends all the info everybody else. we verify that all ports are open for communication. we display a summary and "all green" :slightly_smiling_face:.
then third tab: all green -> deploy ... then test to verify patroni is up.
