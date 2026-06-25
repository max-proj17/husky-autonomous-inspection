#!/usr/bin/env python3
"""
Hold-to-move keyboard teleop for Husky A200.
No extra dependencies — uses stdlib tty/termios/select only.
"""
import sys
import os
import tty
import termios
import select
import threading
import time

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import TwistStamped

LINEAR_SPEEDS  = [0.25, 0.5, 0.75, 1.0, 1.5]  # m/s
ANGULAR_SPEEDS = [0.5,  1.0, 1.5,  2.0, 2.5]  # rad/s
DEFAULT_IDX    = 1
KEY_TIMEOUT    = 0.15  # seconds — must exceed terminal key-repeat interval (~30 ms)


class HoldTeleop(Node):
    def __init__(self):
        super().__init__('hold_teleop')
        self.pub = self.create_publisher(TwistStamped, '/a200_0000/cmd_vel', 10)
        self._last: dict[str, float] = {}
        self._lock = threading.Lock()
        self._idx = DEFAULT_IDX
        self.create_timer(0.05, self._publish)  # 20 Hz

    def touch(self, key: str):
        with self._lock:
            self._last[key] = time.monotonic()

    def _held(self, key: str) -> bool:
        with self._lock:
            return (time.monotonic() - self._last.get(key, 0.0)) < KEY_TIMEOUT

    def _publish(self):
        lin = LINEAR_SPEEDS[self._idx]
        ang = ANGULAR_SPEEDS[self._idx]

        msg = TwistStamped()
        msg.header.stamp = self.get_clock().now().to_msg()

        if self._held('w'):
            msg.twist.linear.x = lin
        elif self._held('s'):
            msg.twist.linear.x = -lin

        if self._held('a'):
            msg.twist.angular.z = ang
        elif self._held('d'):
            msg.twist.angular.z = -ang

        self.pub.publish(msg)

    def speed_up(self):
        self._idx = min(len(LINEAR_SPEEDS) - 1, self._idx + 1)
        _print_speed(self._idx)

    def speed_down(self):
        self._idx = max(0, self._idx - 1)
        _print_speed(self._idx)


def _print_speed(idx: int):
    print(
        f"\r  Speed {idx + 1}/{len(LINEAR_SPEEDS)}: "
        f"{LINEAR_SPEEDS[idx]:.2f} m/s  |  {ANGULAR_SPEEDS[idx]:.2f} rad/s    ",
        end='', flush=True,
    )


def read_keys(saved) -> list[str]:
    """Drain the full input buffer each iteration (up to 32 bytes, 50 ms timeout)."""
    tty.setraw(sys.stdin.fileno())
    ready, _, _ = select.select([sys.stdin], [], [], 0.05)
    keys = [chr(b) for b in os.read(sys.stdin.fileno(), 32)] if ready else []
    termios.tcsetattr(sys.stdin, termios.TCSADRAIN, saved)
    return keys


def main():
    rclpy.init()
    node = HoldTeleop()
    saved = termios.tcgetattr(sys.stdin)

    print("Hold-to-move teleop  |  ESC or Ctrl+C to quit")
    print()
    print("  W = forward    S = backward")
    print("  A = turn left  D = turn right")
    print("  Q = slower     E = faster")
    print()
    _print_speed(DEFAULT_IDX)
    print('\n')

    threading.Thread(target=rclpy.spin, args=(node,), daemon=True).start()

    try:
        while rclpy.ok():
            for key in read_keys(saved):
                if key in ('\x03', '\x1b'):  # Ctrl+C or ESC
                    return
                k = key.lower()
                if k in ('w', 'a', 's', 'd'):
                    node.touch(k)
                elif k == 'q':
                    node.speed_down()
                elif k == 'e':
                    node.speed_up()
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, saved)
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
