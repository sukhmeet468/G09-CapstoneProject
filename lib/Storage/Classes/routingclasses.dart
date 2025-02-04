import 'package:amplify_flutter/amplify_flutter.dart';

class Node {
  String name;
  List<int> data;
  Node? next;
  Node? prev;

  Node(this.name, this.data);
}

class Compass {
  Node? head;

  Compass({String rotation = "CW", List<int>? data}) {
    if (rotation == "CW") {
      append("N", [0, 1]);
      append("NE", [1, 1]);
      append("E", [1, 0]);
      append("SE", [1, -1]);
      append("S", [0, -1]);
      append("SW", [-1, -1]);
      append("W", [-1, 0]);
      append("NW", [-1, 1]);
    } else if (rotation == "CCW") {
      append("N", [0, 1]);
      append("NW", [-1, 1]);
      append("W", [-1, 0]);
      append("SW", [-1, -1]);
      append("S", [0, -1]);
      append("SE", [1, -1]);
      append("E", [1, 0]);
      append("NE", [1, 1]);
    }

    if (data != null) {
      setHead(data);
    }
  }

  void setHead(List<int> data) {
    if (head == null) return;
    Node? current = head;
    do {
      if (current!.data[0] == data[0] && current.data[1] == data[1]) {
        head = current;
        return;
      }
      current = current.next;
    } while (current != head);
  }

  void append(String name, List<int> data) {
    Node newNode = Node(name, data);
    if (head == null) {
      head = newNode;
      newNode.next = newNode;
      newNode.prev = newNode;
    } else {
      Node last = head!.prev!;
      last.next = newNode;
      newNode.prev = last;
      newNode.next = head;
      head!.prev = newNode;
    }
  }

  void printForward() {
    if (head == null) {
      safePrint("List is empty");
      return;
    }
    Node? current = head;
    do {
      safePrint("${current!.name} -> ");
      current = current.next;
    } while (current != head);
    safePrint("... (circular)");
  }

  void printBackward() {
    if (head == null) {
      safePrint("List is empty");
      return;
    }
    Node? current = head;
    do {
      safePrint(current!.name);
      current = current.prev;
    } while (current != head);
    safePrint("... (circular)");
  }
}
