import java.io.File
import java.util.UUID

import akka.actor._
import akka.actor.ActorSystem
import akka.actor.Props
import com.typesafe.config._
import communication.Messages.CyclonManagerStartMessage
import group.{HybridGroupManager}
import peers.{DFPeer, Peer, PeerClassifiers}
import pss.CyclonManager

import scala.collection.mutable

class DataFlasks {
    def initializeActorSystem(confFolderPath: String,
                              systemPathPrefix: String,
                              localId: String,
                              actorSystemName: String) : ActorSystem = {
        val configPath = s"$confFolderPath/${systemPathPrefix}$localId.conf"
        val config = ConfigFactory.parseFile(new File(configPath))

        return ActorSystem(actorSystemName , config)
    }

    def startLocalCyclonManager(localId: String,
                                localPeer: Peer,
                                initialView: mutable.HashMap[UUID, Peer],
                                system: ActorSystem,
                                cyclonManagerPathPrefix: String): ActorRef = {
        val groupManager = new HybridGroupManager(localPeer)
        val remote: ActorRef = system.actorOf(Props(new CyclonManager(localPeer, initialView, groupManager)), name=s"${cyclonManagerPathPrefix}${localId}")

        remote ! CyclonManagerStartMessage(remote)

        return remote
    }
}

object DataFlasks {
    val cyclonManagerPathPrefix = "cyclon"
    val actionManagerPathPrefix = "action"
    val systemPathPrefix = "app"
    val actorSystemName = "ActorFlasks"

    def main(args: Array[String]): Unit = {
        //Parse local peer arguments
        if(args.length < 4) {
            print("Insufficient number of arguments")
            System.exit(1)
        }

        val localId = args(0)
        val localIP = args(1)
        val localPort = args(2)
        val localEnv = if (args(3) == "edge") PeerClassifiers.EDGE else PeerClassifiers.CLOUD
        val confFolderPath = args(4)

        val flasks = new DataFlasks()
        val localPeer = new DFPeer(localId, localIP, localPort.toInt, localEnv)
        val system = flasks.initializeActorSystem(confFolderPath, systemPathPrefix, localId, actorSystemName)

        //Parse known nodes to initial view
        val numberOfArgumentsPerNode = 4
        val numberOfArgumentsForLocalNode = 5

        var initialView: mutable.HashMap[UUID, Peer] = mutable.HashMap()
        val n = util.Random

        for (i <- numberOfArgumentsForLocalNode to args.length - 1) {
            if ((i == numberOfArgumentsForLocalNode + numberOfArgumentsPerNode * initialView.size) && args(i) != null && !args(i).isEmpty) {
                val newPeer = new DFPeer(
                    args(i),
                    args(i+1),
                    args(i+2).toInt,
                    if(args(i+3)==1) PeerClassifiers.EDGE else PeerClassifiers.CLOUD,
                    _age = 0,
                    _position = numberOfArgumentsPerNode/(args.length-1))

                if(!newPeer.uuid.equals(localPeer.uuid) && n.nextInt() < 0.01)
                    initialView += (newPeer.uuid -> newPeer)
            }
        }

        flasks.startLocalCyclonManager(localId, localPeer, initialView, system, cyclonManagerPathPrefix)
    }
}