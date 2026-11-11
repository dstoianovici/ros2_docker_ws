"""Publish a constant Twist on /cmd_vel and log Isaac Sim's /clock."""
from geometry_msgs.msg import Twist
import rclpy
from rclpy.node import Node
from rosgraph_msgs.msg import Clock


class CmdVelDriver(Node):
    def __init__(self):
        super().__init__('cmd_vel_driver')
        self.declare_parameter('linear', 0.2)
        self.declare_parameter('angular', 0.3)
        self.pub = self.create_publisher(Twist, 'cmd_vel', 10)
        self.create_subscription(Clock, 'clock', self._on_clock, 10)
        self.create_timer(0.1, self._tick)
        self._got_clock = False

    def _on_clock(self, msg: Clock):
        if not self._got_clock:
            self.get_logger().info('Receiving /clock from Isaac Sim')
            self._got_clock = True

    def _tick(self):
        msg = Twist()
        msg.linear.x = self.get_parameter('linear').value
        msg.angular.z = self.get_parameter('angular').value
        self.pub.publish(msg)


def main():
    rclpy.init()
    node = CmdVelDriver()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == '__main__':
    main()
