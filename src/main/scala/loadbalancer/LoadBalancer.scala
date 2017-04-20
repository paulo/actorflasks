package loadbalancer

import java.util.UUID

import akka.actor.{Actor, ActorRef}
import communication.Messages._
import peers.Peer

import scala.collection.mutable.ListBuffer
import scala.concurrent.{Await}
import scala.util.{Failure, Success}
import akka.pattern.ask
import akka.util.Timeout

import scala.collection.mutable

// This class is deprecated on this branch
class LoadBalancer(val localPeer: Peer, var cyclonActorRef: ActorRef) extends Actor {

  import config.Configs.LoadBalancerConfig._
  import config.Configs.SystemConfig._

  import system.dispatcher

  var disseminatedRequests: mutable.HashMap[Int, ListBuffer[UUID]] = mutable.HashMap[Int, ListBuffer[UUID]]()
  var disseminatedRequestsLoad: mutable.HashMap[Int, Int] = mutable.HashMap[Int, Int]()
  var currentRequestId = 1
  val randomGenerator = scala.util.Random

  def requestAvailablePeers(actionLoad: Int = 1): PeerInfoResponse = {
    implicit val timeout = Timeout(peerFindingTimeLimit)
    val future = cyclonActorRef ? PeerInfoRequest(initialDissemination)
    return Await.result(future, peerFindingTimeLimit).asInstanceOf[PeerInfoResponse]
  }

  def disseminateAction(requestId: Int, requestLoad: Int, faultToleranceLevel: Int = 1): Unit = {
    disseminatedRequests += (requestId -> new ListBuffer[UUID])
    disseminatedRequestsLoad += (requestId -> requestLoad)
    val peerList = requestAvailablePeers(requestLoad)

    peerList.listBuffer.foreach(peer => {
      getPeerActorRef(peer, "action", context).onComplete{
        case Success(peerRef) =>
          peerRef ! ActionRequestMessage(requestId, requestLoad, localPeer)
        case Failure(f) =>
          println(s"Failure getting peer ${peer.uuid.getLeastSignificantBits}")
      }
    })
  }
  
  def processActionResponseMessage(actionID: Int, responderPeer: Peer): Unit = {
    if(disseminatedRequests.contains(actionID)) {
      if(!disseminatedRequests(actionID).contains(responderPeer.uuid)) {
        disseminatedRequests(actionID) += responderPeer.uuid
        println(s"${disseminatedRequests(actionID).length} peers have responded to request id ${actionID}")
      } else {
        println("Peer already responded to request")
      }
    } else {
      println("Load balancer received not distributed message")
    }
  }

  override def receive: Receive = {
    case LoadBalancerStartMessage =>
      println("Load Balancer Started")
    case msg: UserRequestMessage =>
      disseminateAction(currentRequestId, randomGenerator.nextInt(3))
      currentRequestId += 1
    case msg: ActionResponseMessage =>
      processActionResponseMessage(msg.actionId, msg.responder)
    case _ =>
      println("Unrecognized message")
  }
}