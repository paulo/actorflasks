package loadbalancer

import akka.actor.ActorRef
import communication.Messages.{UserRequestMessage}

import scala.concurrent.duration._

object UserRequestFaker {

  import system.dispatcher
  val system = akka.actor.ActorSystem("ActorFlasks")

  val createRequestInterval = 1 seconds
  var currentRequestId = 0
  val randomGenerator = scala.util.Random
  val maxRequestWeight = 5
  val faultToleranceLevel = 3

  def scheduleMessageDissemination(loadBalancerActor: ActorRef) = {
    system.scheduler.schedule(3000 milliseconds, createRequestInterval, loadBalancerActor,
      UserRequestMessage(
        {currentRequestId += 1; currentRequestId},
        randomGenerator.nextInt(maxRequestWeight),
        randomGenerator.nextInt(faultToleranceLevel)))
  }
}
