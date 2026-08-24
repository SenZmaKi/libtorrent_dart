#include "libtorrent.h"

int main() {
  char version[64] = {};
  if (lt_version(version, sizeof(version)) != 0) return 1;

  void* session = session_create_default();
  if (session == nullptr) return 2;
  session_close(session);
  return 0;
}
