import com.rabbitmq.client.Connection;
import com.rabbitmq.client.Channel;

class Messenger {

    public static void main(String[] args) {
        ConnectionFactory factory = new ConnectionFactory();

        //factory.setUsername("guest"); // Default is 'guest'
        //factory.setPassword("guest"); // Default is 'guest'
        //factory.setVirtualHost("/"); // Default is '/'
        //factory.setHost("localhost"); // Default is 'localhost'
        //factory.setPort(5672); // Default is 5672

        // Also can be done by setting the URL manually
        //factory.setUri("amqp://userName:password@hostName:portNumber/virtualHost");

        Connection conn = factory.newConnection();

        Channel channel = conn.createChannel();

        channel.close(); // Not actually necessary, since closing the connection will do this if it isn't already done
        conn.close();
    }
}