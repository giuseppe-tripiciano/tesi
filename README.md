**Modelli decisionali basati sul calcolo quantistico**

Repository per la tesi di laurea magistrale in Ingegneria Informatica presso l'Università degli Studi di Palermo


**Sommario**

Il calcolo quantistico rappresenta un paradigma emergente per la risoluzione di problemi decisionali, ma la progettazione a livello delle porte circuitali costituisce una sfida sempre maggiore al crescere della complessità del problema; di conseguenza, la ricerca si è orientata verso strumenti con un maggiore livello di astrazione, in grado di derivare circuiti a partire da formulazioni logiche. Nel presente lavoro di tesi viene proposta una metodologia operativa che integra la programmazione logica al calcolo quantistico, e in particolare all'algoritmo di ricerca di Grover, per la progettazione di modelli decisionali basati su vincoli, riprendendo ed estendendo il framework QLPP (*Quantum Logic Programming in Prolog*), introdotto da Pilato et al. (2025), e verificandone l'efficacia e le potenzialità su uno scenario applicativo, il noto benchmark del problema delle n regine. La trattazione illustra dapprima i presupposti teorici di tale metodologia, per poi descrivere l'architettura di base e l'estensione del framework QLPP, comprensiva di un'interfaccia in ambiente Python/Qiskit per l'interazione con Prolog e per la traduzione del circuito allo standard OpenQASM. Infine, vengono presentati ed esaminati in dettaglio il motore logico QLPP e il flusso operativo Python/Qiskit adottati nello scenario applicativo considerato, con una discussione dei risultati ottenuti e delle prospettive future.


**Requisiti**

* Python >= 3.9 con le seguenti dipendenze:

  * pip install "qiskit==2.2.3" 
  * pip install qiskit-aer 
  * pip install mqt.ddsim
  * pip install pyswip pip 
  * pip install matplotlib
  * pip install ipython
  * pip install notebook

* SWI-Prolog

