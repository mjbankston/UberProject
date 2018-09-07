from thespian.actors import *


class Hello(Actor):
    def receiveMessage(self, message, sender):
        self.send(sender, 'Hello, world!')


def say_hello():
    hello = ActorSystem().createActor(Hello)
    print(ActorSystem().ask(hello, 'are you there?', 1.5))


if __name__ == "__main__":
    say_hello()
