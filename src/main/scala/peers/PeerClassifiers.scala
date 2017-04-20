package peers

object PeerClassifiers {
  sealed trait Environment
  case object EDGE extends Environment with Serializable
  case object CLOUD extends Environment with Serializable
}