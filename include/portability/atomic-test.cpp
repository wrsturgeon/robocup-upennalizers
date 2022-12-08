#include <atomic>

int main() {
  std::atomic<int> a;
  a.store(0);
  return a.load();
}
