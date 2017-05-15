To use, build and do somethign like the following to start some clients:

```
stack exec cloudhaskell-countword-exe worker localhost 8000 &
stack exec cloudhaskell-countword-exe worker localhost 8001 &
stack exec cloudhaskell-countword-exe worker localhost 8002 &
stack exec cloudhaskell-countword-exe worker localhost 8003 &
```
Or alternative, a docker-compose.yml file is provided that supports the launching of a set of workers:

```
docker-compose up
```

And then start the manager as follows:

```
stack exec cloudhaskell-countword-exe manager localhost 8005 500
```

You will see console output of this form from from the manager node:

```
Starting Node as Manager
[Manager] Workers spawned
1376
```

and console output of this form from the worker nodes:

```
[Node pid://localhost:8000:0:11] given work: 1
[Node pid://localhost:8000:0:11] finished work.
[Node pid://localhost:8000:0:11] given work: 2
[Node pid://localhost:8000:0:11] finished work.
[Node pid://localhost:8000:0:11] given work: 3
[Node pid://localhost:8000:0:11] finished work.
```
To understand the ouput, consult the code.

__Docker-Compose__

The basic architecture of the work stealing pattern has a manager node as a central component surrounded by a set of
worker nodes. Each worker node is presumed to execute on a different node such that the total computational capacity of
the worker node set are available to us to deliver processing.

Launching worker nodes individually is inconvenient and so I have added a `docker-compose.yml` file to the project. To
launch a set of worker nodes, run:

```
docker-compose up
```

One may now launch a manager node to passwork for these nodes:

```
stack exec cloudhaskell-countword-exe manager localhost 8085 100
```

where the final parameter is the size of the number range (see the code to see the specifics on what the project is calculating). Note that when you execute the system in this way you will not see console output from the worker nodes as the worker function has not been written to gather output to the console.
