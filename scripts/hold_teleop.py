#!/usr/bin/env python3
"""
Hold-to-move keyboard teleop for Husky A200.

Terminals can't detect key-release events, so this uses key-repeat timing:
a held key fires repeat events every ~30 ms. If no event arrives within
KEY_TIMEOUT, the key is considered released and velocity drops to zero.
"""
import sys
import tty
import termios
import select
import threading
import time

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import TwistStamped

LINEAR_SPEED = 0.5   # m/s
ANGULAR_SPEED = 1.0  # rad/s
KEY_TIMEOUT   = 0.15 # seconds — must exceed key-repeat interval (~30 ms)


class HoldTeleop(Node):
    def __init__(self):
        super().__init__('hold_teleop')
        self.pub = self.create_publisher(TwistStamped, '/a200_0000/cmd_vel', 10)
        self._last: dict[str, float] = {}
        self._lock = threading.Lock()
        self.create_timer(0.05, self._publish)  # 20 Hz

    def touch(self, key: str):
        with self._lock:
            self._last[key] = time.monotonic()

    def _held(self, key: str) -> bool:
        with self._lock:
            return (time.monotonic() - self._last.get(key, 0.0)) < KEY_TIMEOUT

    def _publish(self):
        msg = TwistStamped()
        msg.header.stamp = self.get_clock().now().to_msg()

        if self._held('w'):
            msg.twist.linear.x = LINEAR_SPEED
        elif self._held('s'):
            msg.twist.linear.x = -LINEAR_SPEED

        if self._held('a'):
            msg.twist.angular.z = ANGULAR_SPEED
        elif self._held('d'):
            msg.twist.angular.z = -ANGULAR_SPEED

        self.pub.publish(msg)


def read_key(saved: list) -> str:
    """Read one keypress with a 50 ms timeout. Returns '' on timeout."""
    tty.setraw(sys.stdin.fileno())
    ready, _, _ = select.select([sys.stdin], [], [], 0.05)
    key = sys.stdin.read(1) if ready else ''
    termios.tcsetattr(sys.stdin, termios.TCSADRAIN, saved)
    return key


def main():
    rclpy.init()
    node = HoldTeleop()
    saved = termios.tcgetattr(sys.stdin)

    print("Hold-to-move teleop  |  Q or Ctrl+C to quit")
    print()
    print("  W = forward    S = backward")
    print("  A = turn left  D = turn right")
    print()
    print("Hold a key to move — release to stop.")
    print("W+A / W+D combinations work simultaneously.")
    print()

    threading.Thread(target=rclpy.spin, args=(node,), daemon=True).start()

    try:
        while rclpy.ok():
            key = read_key(saved)
            if not key:
                continue
            if key == '\x03' or key.lower() == 'q':  # Ctrl+C or Q
                break
            if key.lower() in ('w', 'a', 's', 'd'):
                node.touch(key.lower())
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, saved)
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
