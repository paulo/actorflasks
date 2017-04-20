package group
import java.util.UUID

import config.Configs.HybridGroupManagerConfig
import peers.{Peer, PeerClassifiers}

import scala.collection.mutable

class HybridGroupManager(localPeer: Peer) {
  import config.Configs.HybridGroupManagerConfig._

  var localViewEdge: mutable.HashMap[UUID, Peer] = mutable.HashMap[UUID, Peer]()
  var localViewCloud: mutable.HashMap[UUID, Peer] = mutable.HashMap[UUID, Peer]()
  var numberOfGroupsCloud = 1
  var numberOfGroupsEdge = 1
  var currentGroupCloud = 1
  var currentGroupEdge = 1
  var cycle = 1

  def refreshGroup(newPeerList: List[Peer]): Unit = {
    newPeerList.foreach{ peer =>
      if(isSameGroupAsLocal(peer)) {
        if(peer.environment == PeerClassifiers.EDGE) {
          localViewEdge += (peer.uuid -> peer)
        } else {
          localViewCloud += (peer.uuid -> peer)
        }
      }
    }

    cleanLocalViews
    tryMergeSplitGroups

    currentGroupEdge = calculateGroupNumber(localPeer.position, numberOfGroupsEdge)
    currentGroupCloud = calculateGroupNumber(localPeer.position, numberOfGroupsCloud)
    cycle += 1
    println(s"CYCLE: $cycle | NUM_EDGE_GROUPS: $numberOfGroupsEdge | edge group is $currentGroupEdge")
    println(s"CYCLE: $cycle | NUM_CLOUD_GROUPS: $numberOfGroupsCloud | cloud group is $currentGroupCloud")
  }

  def cleanLocalViews: Unit = {
    localViewEdge = localViewEdge.filter(entry => isSameGroupAsLocal(entry._2))
    localViewCloud = localViewCloud.filter(entry => isSameGroupAsLocal(entry._2))
  }

  def isSameGroupAsLocal(peer: Peer): Boolean = {
    if (peer.environment == PeerClassifiers.EDGE) {
      return calculateGroupNumber(peer.position, numberOfGroupsEdge) == currentGroupEdge
    } else {
      return calculateGroupNumber(peer.position, numberOfGroupsCloud) == currentGroupCloud
    }
  }

  def calculateGroupNumber(position: Double, numberOfGroups: Double): Int = {
    return Math.ceil(position * numberOfGroups).toInt
  }

  def tryMergeSplitGroups: Unit = {
    if(localViewEdge.size < minGroupSizeEdge && numberOfGroupsEdge > 1) {
      numberOfGroupsEdge /= HybridGroupManagerConfig.growingFactor
    } else {
      if (localViewEdge.size > maxGroupSizeEdge) {
        numberOfGroupsEdge *= HybridGroupManagerConfig.growingFactor
      }
    }

    if(localViewCloud.size < minGroupSizeCloud && numberOfGroupsCloud > 1) {
      numberOfGroupsCloud /= HybridGroupManagerConfig.growingFactor
    } else {
      if (localViewCloud.size > maxGroupSizeCloud) {
        numberOfGroupsCloud *= HybridGroupManagerConfig.growingFactor
      }
    }
  }
}