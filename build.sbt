name := "actorflasks"

version := "1.0"

scalaVersion := "2.12.1"

libraryDependencies ++= Seq(
  "com.typesafe.akka" %% "akka-actor" % "2.5.0",
  "com.typesafe.akka" %% "akka-remote" % "2.5.0",
  "com.typesafe.akka" %% "akka-testkit" % "2.5.0" % "test",
  "org.scalatest" %% "scalatest" % "3.0.0" % "test",
  "com.typesafe" % "config" % "1.2.1"
)