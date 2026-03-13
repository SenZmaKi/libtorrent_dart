# libtorrent C++ Public API Specification

**Version**: libtorrent 2.0.11 (commit: 163d36465)  
**Repository**: https://github.com/arvidn/libtorrent  
**Purpose**: Complete public API reference for achieving parity with libtorrent_dart

---

## Table of Contents

1. [Overview](#overview)
2. [Header Files Inventory](#header-files-inventory)
3. [Core API Components](#core-api-components)
4. [Session Management](#session-management)
5. [Torrent Operations](#torrent-operations)
6. [Alert System](#alert-system)
7. [Settings & Configuration](#settings--configuration)
8. [File & Storage](#file--storage)
9. [Peer Management](#peer-management)
10. [Tracker Management](#tracker-management)
11. [DHT Operations](#dht-operations)
12. [Network & Connectivity](#network--connectivity)
13. [Data Structures](#data-structures)
14. [Enumerations & Constants](#enumerations--constants)
15. [Utility Functions](#utility-functions)

---

## Overview

libtorrent is a feature-complete C++ BitTorrent implementation focusing on efficiency and scalability. The public API is exposed through **272 header files** organized under `include/libtorrent/`.

### API Philosophy
- **Handle-based design**: Objects are manipulated through handles (e.g., `torrent_handle`, `session_handle`)
- **Asynchronous alerts**: Events delivered through an alert queue
- **Settings-based configuration**: `settings_pack` for runtime configuration
- **Type-safe enums**: Scoped enumerations for flags and states
- **Modern C++**: Uses C++14/17 features (std::shared_ptr, std::string_view, etc.)

---

## Header Files Inventory

### Core Session & Torrent Management (7 files)
| File | Description |
|------|-------------|
| `session.hpp` | Main session class for managing torrents |
| `session_handle.hpp` | Non-owning reference to session |
| `session_params.hpp` | Session construction parameters |
| `session_status.hpp` | Session-wide statistics |
| `session_stats.hpp` | Performance counters |
| `torrent_handle.hpp` | Handle to individual torrent |
| `torrent_info.hpp` | Torrent metadata and file information |

### Status & Information (4 files)
| File | Description |
|------|-------------|
| `torrent_status.hpp` | Current state of a torrent |
| `torrent_flags.hpp` | Torrent behavior flags |
| `add_torrent_params.hpp` | Parameters for adding torrents |
| `announce_entry.hpp` | Tracker announce information |

### Alerts & Events (2 files)
| File | Description |
|------|-------------|
| `alert.hpp` | Base alert class and alert queue |
| `alert_types.hpp` | All concrete alert types (50+) |

### Settings & Configuration (3 files)
| File | Description |
|------|-------------|
| `settings_pack.hpp` | Runtime configuration settings |
| `download_priority.hpp` | File/piece download priorities |
| `config.hpp` | Compile-time configuration |

### File & Storage (10 files)
| File | Description |
|------|-------------|
| `file_storage.hpp` | File layout in a torrent |
| `storage_defs.hpp` | Storage mode definitions |
| `storage.hpp` | Custom storage interface |
| `disk_interface.hpp` | Disk I/O interface |
| `disk_buffer_holder.hpp` | RAII disk buffer wrapper |
| `disk_observer.hpp` | Disk operation observer |
| `mmap_disk_io.hpp` | Memory-mapped disk I/O |
| `posix_disk_io.hpp` | POSIX disk I/O |
| `disabled_disk_io.hpp` | No-op disk I/O (testing) |
| `part_file.hpp` | Partial file management |

### Torrent File Operations (5 files)
| File | Description |
|------|-------------|
| `create_torrent.hpp` | Create new .torrent files |
| `load_torrent.hpp` | Load .torrent files |
| `magnet_uri.hpp` | Parse/generate magnet links |
| `write_resume_data.hpp` | Serialize resume data |
| `read_resume_data.hpp` | Deserialize resume data |

### Peer Management (13 files)
| File | Description |
|------|-------------|
| `peer_info.hpp` | Connected peer information |
| `peer_id.hpp` | 20-byte peer identifier |
| `peer_class.hpp` | Peer priority classification |
| `peer_class_set.hpp` | Set of peer classes |
| `peer_class_type_filter.hpp` | Filter peers by type |
| `peer_connection.hpp` | Abstract peer connection |
| `peer_connection_handle.hpp` | Peer connection handle |
| `peer_connection_interface.hpp` | Peer connection interface |
| `peer_request.hpp` | Block request from peer |
| `bt_peer_connection.hpp` | BitTorrent protocol peer |
| `web_peer_connection.hpp` | HTTP/FTP seed connection |
| `torrent_peer.hpp` | Peer state tracking |
| `torrent_peer_allocator.hpp` | Peer memory allocator |

### Network & Connectivity (16 files)
| File | Description |
|------|-------------|
| `socket.hpp` | Socket abstractions |
| `address.hpp` | IP address types |
| `socket_type.hpp` | Socket type wrapper |
| `socket_io.hpp` | Socket I/O utilities |
| `udp_socket.hpp` | UDP socket implementation |
| `ssl.hpp` | SSL/TLS support |
| `ssl_stream.hpp` | SSL stream wrapper |
| `proxy_base.hpp` | Proxy connection base |
| `socks5_stream.hpp` | SOCKS5 proxy |
| `i2p_stream.hpp` | I2P anonymous network |
| `http_stream.hpp` | HTTP proxy |
| `http_connection.hpp` | HTTP client connection |
| `http_parser.hpp` | HTTP protocol parser |
| `parse_url.hpp` | URL parsing utilities |
| `enum_net.hpp` | Network interface enumeration |
| `ip_filter.hpp` | IP address filtering |

### Trackers & Discovery (6 files)
| File | Description |
|------|-------------|
| `tracker_manager.hpp` | Tracker request manager |
| `http_tracker_connection.hpp` | HTTP tracker connection |
| `udp_tracker_connection.hpp` | UDP tracker connection |
| `lsd.hpp` | Local Service Discovery |
| `upnp.hpp` | UPnP port mapping |
| `natpmp.hpp` | NAT-PMP port mapping |

### DHT (Distributed Hash Table) (10 files)
Located in `include/libtorrent/kademlia/`:
| File | Description |
|------|-------------|
| `dht_state.hpp` | DHT routing table state |
| `dht_storage.hpp` | DHT storage interface |
| `dht_tracker.hpp` | DHT tracker implementation |
| `item.hpp` | DHT mutable/immutable items |
| `node.hpp` | DHT node implementation |
| `node_id.hpp` | DHT node identifier |
| `observer.hpp` | DHT RPC observer |
| `routing_table.hpp` | DHT routing table |
| `rpc_manager.hpp` | DHT RPC manager |
| `traversal_algorithm.hpp` | DHT search algorithms |

### Hashing & Cryptography (7 files)
| File | Description |
|------|-------------|
| `sha1_hash.hpp` | SHA-1 hash type (20 bytes) |
| `sha256.hpp` | SHA-256 hash type (32 bytes) |
| `hasher.hpp` | Incremental hasher |
| `info_hash.hpp` | v1/v2 info-hash wrapper |
| `crc32c.hpp` | CRC32C checksum |
| `pe_crypto.hpp` | Protocol encryption |
| `fingerprint.hpp` | Client fingerprint |

### Data Encoding (4 files)
| File | Description |
|------|-------------|
| `bdecode.hpp` | Bencode decoder |
| `bencode.hpp` | Bencode encoder |
| `entry.hpp` | Variant type for bencoding |
| `xml_parse.hpp` | XML parser utilities |

### Piece Management (8 files)
| File | Description |
|------|-------------|
| `piece_block.hpp` | Piece block identifier |
| `piece_block_progress.hpp` | Block transfer progress |
| `piece_picker.hpp` | Piece selection algorithm |
| `hash_picker.hpp` | Hash checking scheduler |
| `bitfield.hpp` | Compact bit array |
| `bloom_filter.hpp` | Probabilistic set |
| `request_blocks.hpp` | Block request queue |
| `resolve_links.hpp` | Hardlink resolution |

### Utilities & Support (30+ files)
| File | Description |
|------|-------------|
| `version.hpp` | Library version information |
| `error.hpp` | Error category definitions |
| `error_code.hpp` | Error code wrapper |
| `operations.hpp` | Operation type enumeration |
| `flags.hpp` | Type-safe flags template |
| `units.hpp` | Type-safe unit wrappers |
| `time.hpp` | Time utilities |
| `span.hpp` | Span/view template |
| `optional.hpp` | Optional value wrapper |
| `string_view.hpp` | String view type |
| `string_util.hpp` | String manipulation |
| `hex.hpp` | Hex encoding/decoding |
| `utf8.hpp` | UTF-8 validation |
| `copy_ptr.hpp` | Copy-on-write pointer |
| `identify_client.hpp` | Client identification |
| `platform_util.hpp` | Platform-specific utilities |
| `debug.hpp` | Debug assertions |
| `assert.hpp` | Assert macros |
| `fwd.hpp` | Forward declarations |
| `link.hpp` | Export macros |
| `random.hpp` | Random number generation |
| `stat.hpp` | Transfer statistics |
| `stat_cache.hpp` | File stat cache |
| `sliding_average.hpp` | Moving average calculator |
| `io_context.hpp` | Asio I/O context wrapper |
| `stack_allocator.hpp` | Stack-based allocator |
| `tailqueue.hpp` | Intrusive linked list |
| `index_range.hpp` | Index range utilities |
| `vector_utils.hpp` | Vector helpers |
| `union_endpoint.hpp` | Union of TCP/UDP endpoints |
| `close_reason.hpp` | Connection close reasons |

### Extensions (3 files)
| File | Description |
|------|-------------|
| `extensions.hpp` | Extension plugin interface |
| `extensions/ut_metadata.hpp` | Metadata exchange extension |
| `extensions/ut_pex.hpp` | Peer exchange extension |
| `extensions/smart_ban.hpp` | Smart peer banning |

---

## Core API Components

### 1. Session Management

**File**: `include/libtorrent/session.hpp`

#### class `session`
Main entry point for the library. Manages all torrents, network connections, and settings.

**Constructor**:
```cpp
session();
explicit session(session_params params);
session(session_params params, session_flags_t flags);
```

**Destructor**:
```cpp
~session();
```

**Key Methods**:
```cpp
// Torrent Management
torrent_handle add_torrent(add_torrent_params const& params);
torrent_handle add_torrent(add_torrent_params&& params);
void async_add_torrent(add_torrent_params const& params);
void async_add_torrent(add_torrent_params&& params);
void remove_torrent(torrent_handle const& h, remove_flags_t options = {});

// Finding Torrents
torrent_handle find_torrent(sha1_hash const& info_hash);
torrent_handle find_torrent(sha256_hash const& info_hash);
std::vector<torrent_handle> get_torrents() const;
std::vector<torrent_status> get_torrent_status(
    std::function<bool(torrent_status const&)> const& pred,
    status_flags_t flags = {}) const;

// Session Control
void pause();
void resume();
bool is_paused() const;

// Settings
void apply_settings(settings_pack const& s);
void apply_settings(settings_pack&& s);
settings_pack get_settings() const;

// Alerts
void set_alert_notify(std::function<void()> const& fun);
std::vector<alert*> pop_alerts();
void pop_alerts(std::vector<alert*>* alerts);
alert* wait_for_alert(time_duration max_wait);

// Statistics
void post_session_stats();
void post_torrent_updates(status_flags_t flags = status_flags_t::all());
void post_dht_stats();

// State Management
session_params session_state(save_state_flags_t flags = save_state_flags_t::all()) const;

// DHT Operations
void set_dht_settings(dht::dht_settings const& settings);
dht::dht_settings get_dht_settings() const;
void set_dht_state(dht::dht_state&& state);
void set_dht_state(dht::dht_state const& state);
bool is_dht_running() const;
void dht_get_item(sha1_hash const& target);
void dht_get_item(std::array<char, 32> key, std::string salt = "");
void dht_put_item(entry data);
void dht_put_item(std::array<char, 32> key, 
                   std::function<void(entry&, std::array<char,64>&, std::int64_t&, std::string const&)> cb,
                   std::string salt = "");
void dht_get_peers(sha1_hash const& info_hash);
void dht_announce(sha1_hash const& info_hash, int port = 0, dht::announce_flags_t flags = {});
void add_dht_node(std::pair<std::string, int> const& node);
std::vector<std::pair<sha1_hash, udp::endpoint>> dht_sample_infohashes(
    udp::endpoint const& ep, sha1_hash const& target);

// Port Forwarding
void add_port_mapping(portmap_protocol protocol, int external_port, int local_port);
void delete_port_mapping(port_mapping_t handle);
std::vector<port_mapping_t> add_port_mapping(
    portmap_protocol t, int external_port, int local_port);

// Listen Interface
void listen_on(int port, error_code& ec, 
               const char* net_interface = nullptr, int flags = 0);
std::uint16_t listen_port() const;
std::uint16_t ssl_listen_port() const;

// Peer Classes
peer_class_t create_peer_class(char const* name);
void delete_peer_class(peer_class_t cid);
peer_class_info get_peer_class(peer_class_t cid) const;
void set_peer_class(peer_class_t cid, peer_class_info const& pci);

// IP Filtering
void set_ip_filter(ip_filter const& f);
ip_filter get_ip_filter() const;

// Port Filtering
void set_port_filter(port_filter const& f);

// Proxy
void set_peer_proxy(proxy_settings const& s);
void set_web_seed_proxy(proxy_settings const& s);
void set_tracker_proxy(proxy_settings const& s);
proxy_settings peer_proxy() const;
proxy_settings web_seed_proxy() const;
proxy_settings tracker_proxy() const;

// Encryption
void set_peer_id(peer_id const& pid);
peer_id id() const;

// Session ID
void set_key(std::uint32_t key);
std::uint32_t key() const;
```

#### class `session_handle`
Non-owning reference to a session, safe to pass around.

```cpp
class session_handle {
    // Contains same methods as session class
    // Allows multiple handles to same session
    // Destructor does not close session
};
```

#### class `session_proxy`
Returned by `session::abort()` for asynchronous shutdown.

```cpp
class session_proxy {
    ~session_proxy(); // Blocks until session fully closed
};
```

---

### 2. Torrent Operations

**File**: `include/libtorrent/torrent_handle.hpp`

#### class `torrent_handle`
Handle to a torrent within a session. All operations are thread-safe.

**Status & Information**:
```cpp
torrent_status status(status_flags_t flags = status_flags_t::all()) const;
void get_download_queue(std::vector<partial_piece_info>& queue) const;
void post_download_queue() const;
void get_peer_info(std::vector<peer_info>& v) const;
void post_peer_info() const;
torrent_info const& torrent_file() const;
std::shared_ptr<const torrent_info> torrent_file_with_hashes() const;
std::vector<announce_entry> trackers() const;
void post_trackers() const;
std::vector<std::string> url_seeds() const;
std::vector<std::string> http_seeds() const;
```

**File Operations**:
```cpp
void file_progress(std::vector<std::int64_t>& progress, file_progress_flags_t flags = {}) const;
void post_file_progress(file_progress_flags_t flags) const;
std::vector<open_file_state> file_status() const;
void clear_error();
```

**Piece Operations**:
```cpp
bool have_piece(piece_index_t piece) const;
void read_piece(piece_index_t piece) const;
void add_piece(piece_index_t piece, char const* data, add_piece_flags_t flags = {});
void add_piece(piece_index_t piece, std::vector<char> data, add_piece_flags_t flags = {});
```

**Priority & Limits**:
```cpp
// File Priorities
void file_priority(file_index_t index, download_priority_t priority) const;
download_priority_t file_priority(file_index_t index) const;
void prioritize_files(std::vector<download_priority_t> const& files) const;
std::vector<download_priority_t> get_file_priorities() const;
void post_file_progress(file_progress_flags_t flags) const;

// Piece Priorities
void piece_priority(piece_index_t index, download_priority_t priority) const;
download_priority_t piece_priority(piece_index_t index) const;
void prioritize_pieces(std::vector<download_priority_t> const& pieces) const;
void prioritize_pieces(std::vector<std::pair<piece_index_t, download_priority_t>> const& pieces) const;
std::vector<download_priority_t> get_piece_priorities() const;

// Piece Deadlines
void set_piece_deadline(piece_index_t index, int deadline, 
                        deadline_flags_t flags = {}) const;
void reset_piece_deadline(piece_index_t index) const;
void clear_piece_deadlines() const;

// Bandwidth Limits
int download_limit() const;
int upload_limit() const;
void set_download_limit(int limit) const;
void set_upload_limit(int limit) const;

// Connection Limits
void set_max_uploads(int max_uploads) const;
int max_uploads() const;
void set_max_connections(int max_connections) const;
int max_connections() const;
```

**Control**:
```cpp
void pause(pause_flags_t flags = {}) const;
void resume() const;
void set_flags(torrent_flags_t flags) const;
void set_flags(torrent_flags_t flags, torrent_flags_t mask) const;
void unset_flags(torrent_flags_t flags) const;
torrent_flags_t flags() const;

void flush_cache() const;
void force_recheck() const;
void force_dht_announce() const;
void force_reannounce(int seconds = 0, int tracker_idx = -1, 
                      reannounce_flags_t flags = {}) const;
void scrape_tracker(int idx = -1) const;
```

**Tracker Management**:
```cpp
void replace_trackers(std::vector<announce_entry> const& trackers) const;
void add_tracker(announce_entry const& e) const;

// Web Seeds
void add_url_seed(std::string const& url) const;
void remove_url_seed(std::string const& url) const;
void add_http_seed(std::string const& url) const;
void remove_http_seed(std::string const& url) const;
```

**Resume Data**:
```cpp
void save_resume_data(resume_data_flags_t flags = {}) const;
add_torrent_params get_resume_data(resume_data_flags_t flags = {}) const;
bool need_save_resume_data() const;
void force_lsd_announce() const;
```

**Metadata**:
```cpp
bool set_metadata(span<char const> metadata) const;
bool is_valid() const;
bool in_session() const;
```

**Queue Position**:
```cpp
void queue_position_up() const;
void queue_position_down() const;
void queue_position_top() const;
void queue_position_bottom() const;
void queue_position_set(queue_position_t p) const;
queue_position_t queue_position() const;
```

**Peers**:
```cpp
void connect_peer(tcp::endpoint const& adr, peer_source_flags_t source = {}, 
                  pex_flags_t flags = {}) const;
void clear_peers();

// Peer Classes
void set_peer_class(peer_class_t const pc) const;
```

**Info Hash**:
```cpp
sha1_hash info_hash() const;
info_hash_t info_hashes() const;
```

**Comparison**:
```cpp
bool operator==(torrent_handle const& h) const;
bool operator!=(torrent_handle const& h) const;
bool operator<(torrent_handle const& h) const;
std::size_t hash_value() const;
```

---

### 3. Alert System

**File**: `include/libtorrent/alert.hpp`, `include/libtorrent/alert_types.hpp`

#### class `alert`
Base class for all alerts.

```cpp
class alert {
public:
    virtual ~alert();
    
    // Alert type ID
    virtual int type() const noexcept = 0;
    
    // Alert category flags
    virtual alert_category_t category() const noexcept = 0;
    
    // Human-readable message
    virtual char const* what() const noexcept = 0;
    virtual std::string message() const = 0;
    
    // Timestamp when alert was posted
    time_point timestamp() const;
};
```

#### Alert Categories
```cpp
enum class alert_category : std::uint32_t {
    error = 0x1,
    peer = 0x2,
    port_mapping = 0x4,
    storage = 0x8,
    tracker = 0x10,
    connect = 0x20,
    status = 0x40,
    ip_block = 0x80,
    performance_warning = 0x100,
    dht = 0x200,
    stats = 0x400,
    session_log = 0x800,
    torrent_log = 0x1000,
    peer_log = 0x2000,
    incoming_request = 0x4000,
    dht_operation = 0x8000,
    port_mapping_log = 0x10000,
    picker_log = 0x20000,
    file_progress = 0x40000,
    piece_progress = 0x80000,
    upload = 0x100000,
    block_progress = 0x200000,
    
    all = 0xffffffff
};
```

#### Key Alert Types

**Torrent Alerts**:
```cpp
struct torrent_added_alert : torrent_alert;
struct torrent_removed_alert : torrent_alert;
struct torrent_deleted_alert : torrent_alert;
struct torrent_paused_alert : torrent_alert;
struct torrent_resumed_alert : torrent_alert;
struct torrent_checked_alert : torrent_alert;
struct torrent_finished_alert : torrent_alert;
struct torrent_error_alert : torrent_alert {
    error_code error;
    std::string error_file;
};
```

**State Update**:
```cpp
struct state_changed_alert : torrent_alert {
    torrent_status::state_t state;
    torrent_status::state_t prev_state;
};

struct state_update_alert : alert {
    std::vector<torrent_status> status;
};
```

**Piece/Block Progress**:
```cpp
struct piece_finished_alert : torrent_alert {
    piece_index_t piece_index;
};

struct block_finished_alert : peer_alert {
    piece_index_t piece_index;
    int block_index;
};

struct hash_failed_alert : torrent_alert {
    piece_index_t piece_index;
};

struct read_piece_alert : torrent_alert {
    error_code const ec;
    std::shared_ptr<char> const buffer;
    piece_index_t const piece;
    int const size;
};
```

**Tracker Alerts**:
```cpp
struct tracker_reply_alert : tracker_alert {
    int num_peers;
};

struct tracker_announce_alert : tracker_alert {
    announce_event event;
};

struct tracker_error_alert : tracker_alert {
    int times_in_row;
    int status_code;
    error_code error;
    std::string error_message;
};

struct tracker_warning_alert : tracker_alert {
    std::string warning_message;
};
```

**Peer Alerts**:
```cpp
struct peer_connect_alert : peer_alert;
struct peer_disconnected_alert : peer_alert {
    operation_t op;
    error_code error;
    close_reason_t reason;
};

struct peer_ban_alert : peer_alert;
struct peer_unsnubbed_alert : peer_alert;
struct peer_snubbed_alert : peer_alert;
struct peer_error_alert : peer_alert {
    operation_t op;
    error_code error;
};
```

**Metadata Alerts**:
```cpp
struct metadata_received_alert : torrent_alert;
struct metadata_failed_alert : torrent_alert {
    error_code error;
};
```

**Resume Data Alerts**:
```cpp
struct save_resume_data_alert : torrent_alert {
    add_torrent_params params;
};

struct save_resume_data_failed_alert : torrent_alert {
    error_code error;
};
```

**File Alerts**:
```cpp
struct file_renamed_alert : torrent_alert {
    std::string name;
    file_index_t index;
};

struct file_error_alert : torrent_alert {
    error_code error;
    file_index_t file;
    operation_t op;
};

struct file_completed_alert : torrent_alert {
    file_index_t index;
};
```

**DHT Alerts**:
```cpp
struct dht_stats_alert : alert {
    std::vector<dht_routing_bucket> routing_table;
    std::vector<dht_lookup> requests;
    sha1_hash id;
    udp::endpoint local_endpoint;
};

struct dht_bootstrap_alert : alert;
struct dht_get_peers_alert : dht_alert;
struct dht_announce_alert : dht_alert;

struct dht_reply_alert : tracker_alert {
    int num_peers;
};

struct dht_immutable_item_alert : alert {
    sha1_hash target;
    entry item;
};

struct dht_mutable_item_alert : alert {
    std::array<char, 32> key;
    std::array<char, 64> signature;
    std::int64_t seq;
    std::string salt;
    entry item;
    bool authoritative;
};

struct dht_put_alert : alert {
    sha1_hash target;
    std::array<char, 32> public_key;
    std::array<char, 64> signature;
    std::string salt;
    std::int64_t seq;
    int num_success;
};
```

**Session Stats**:
```cpp
struct session_stats_alert : alert {
    span<std::int64_t const> counters() const;
};

struct session_stats_header_alert : alert {
    // Contains metric names/descriptions
};
```

**Performance Warnings**:
```cpp
struct performance_alert : torrent_alert {
    enum performance_warning_t {
        outstanding_disk_buffer_limit_reached,
        outstanding_request_limit_reached,
        upload_limit_too_low,
        download_limit_too_low,
        send_buffer_watermark_too_low,
        too_many_optimistic_unchoke_slots,
        bittyrant_with_no_uplimit,
        too_high_disk_queue_limit,
        aio_limit_reached,
        deprecated_disk_io
    };
    
    performance_warning_t warning_code;
};
```

**Port Mapping Alerts**:
```cpp
struct portmap_alert : alert {
    port_mapping_t mapping;
    portmap_type map_type;
    portmap_protocol map_protocol;
};

struct portmap_error_alert : alert {
    port_mapping_t mapping;
    portmap_type map_type;
    error_code error;
    portmap_protocol map_protocol;
};
```

---

### 4. Settings & Configuration

**File**: `include/libtorrent/settings_pack.hpp`

#### class `settings_pack`
Container for all configurable settings in a session.

```cpp
class settings_pack {
public:
    settings_pack();
    
    // Setters
    void set_str(int name, std::string val);
    void set_int(int name, int val);
    void set_bool(int name, bool val);
    
    // Getters
    bool has_val(int name) const;
    std::string const& get_str(int name) const;
    int get_int(int name) const;
    bool get_bool(int name) const;
    
    // Clearing
    void clear();
    void clear(int name);
};
```

#### Integer Settings (enum `int_types`)

**Connection Limits**:
```cpp
connections_limit           // Global max connections
connections_slack          // Extra connections for web seeds
unchoke_slots_limit        // Max unchoked peers
```

**Upload/Download Limits**:
```cpp
upload_rate_limit          // Global upload rate (bytes/sec)
download_rate_limit        // Global download rate (bytes/sec)
local_upload_rate_limit    // LAN upload rate
local_download_rate_limit  // LAN download rate
dht_upload_rate_limit      // DHT upload rate
```

**Listen Port**:
```cpp
listen_queue_size          // Socket listen backlog
max_retry_port_bind        // Port bind retry attempts
alert_queue_size           // Alert queue size
max_metadata_size          // Max .torrent metadata size
```

**DHT**:
```cpp
dht_announce_interval      // DHT announce frequency (seconds)
dht_max_peers              // Max peers per torrent in DHT
dht_max_dht_items         // Max DHT items to store
```

**Disk Cache**:
```cpp
cache_size                 // Disk cache size (16 KiB blocks)
cache_buffer_chunk_size    // Buffer chunk size
cache_expiry              // Cache entry expiration (seconds)
disk_io_write_mode        // Write mode (enable_os_cache, etc.)
disk_io_read_mode         // Read mode
```

**Timeouts**:
```cpp
peer_timeout               // Peer inactivity timeout (seconds)
urlseed_timeout           // Web seed timeout
tracker_completion_timeout // Tracker completion timeout
tracker_receive_timeout    // Tracker receive timeout
stop_tracker_timeout       // Stop announce timeout
request_timeout           // Piece request timeout
```

**Algorithm**:
```cpp
choking_algorithm          // Choking algorithm
    // fixed_slots_choker = 0
    // rate_based_choker = 1
    // bittyrant_choker = 2
    
seed_choking_algorithm     // Seed choking algorithm
    // round_robin = 0
    // fastest_upload = 1
    // anti_leech = 2
```

**Peer Class**:
```cpp
peer_tos                   // IP TOS byte for peers
```

**UTP**:
```cpp
utp_target_delay          // Target delay (microseconds)
utp_gain_factor          // Gain factor
utp_min_timeout          // Min timeout (milliseconds)
utp_syn_resends          // SYN resend attempts
utp_fin_resends          // FIN resend attempts
utp_num_resends          // Data resend attempts
utp_connect_timeout      // Connection timeout
```

**Mixed Mode**:
```cpp
mixed_mode_algorithm      // prefer_tcp = 0, peer_proportional = 1
```

**Pieces**:
```cpp
suggest_mode              // Suggest mode behavior
max_queued_disk_bytes     // Max queued disk bytes
handshake_timeout         // Handshake timeout
send_buffer_low_watermark // Send buffer watermark
send_buffer_watermark     // Send buffer high watermark
```

#### Boolean Settings (enum `bool_types`)

**Protocol**:
```cpp
enable_incoming_utp       // Allow incoming uTP connections
enable_outgoing_utp       // Allow outgoing uTP connections
enable_incoming_tcp       // Allow incoming TCP connections
enable_outgoing_tcp       // Allow outgoing TCP connections
```

**DHT**:
```cpp
enable_dht                // Enable DHT
```

**Discovery**:
```cpp
enable_lsd                // Local Service Discovery
enable_upnp               // UPnP port mapping
enable_natpmp             // NAT-PMP port mapping
```

**IP Filtering**:
```cpp
no_connect_privileged_ports // Don't connect to ports < 1024
```

**Encryption**:
```cpp
prefer_rc4                // Prefer RC4 encryption
enable_outgoing_encryption // Enable encryption for outgoing
enable_incoming_encryption // Enable encryption for incoming
force_encryption          // Force encryption
```

**Seeding**:
```cpp
seed_time_limit_not_met   // Don't stop until seed_time_limit met
auto_managed              // Auto-manage torrents
rate_limit_ip_overhead    // Include protocol overhead in rate limits
announce_to_all_trackers  // Announce to all trackers
announce_to_all_tiers     // Announce to all tiers
```

**Misc**:
```cpp
allow_multiple_connections_per_ip  // Allow multiple from same IP
smooth_connects           // Spread out connections
always_send_user_agent    // Always send user-agent
apply_ip_filter_to_trackers // Apply IP filter to trackers
use_dht_as_fallback      // Use DHT only if no tracker
upnp_ignore_nonrouters   // Ignore non-router UPnP
use_parole_mode          // Parole mode for questionable peers
prefer_udp_trackers      // Prefer UDP trackers
strict_super_seeding     // Strict super-seeding
support_share_mode       // Support share mode
report_redundant_bytes   // Report redundant bytes
listen_system_port_fallback // Fall back to OS-assigned port
announce_crypto_support  // Announce encryption support
enable_set_file_valid_data // Enable set_file_valid_data
```

#### String Settings (enum `string_types`)

```cpp
user_agent                // HTTP User-Agent header
announce_ip              // IP address to announce
handshake_client_version // Version in BT handshake
outgoing_interfaces      // Bind outgoing to specific interfaces
listen_interfaces        // Interfaces to listen on
    // Format: "interface:port[,interface:port]..."
    // Example: "0.0.0.0:6881,[::]::6881"
dht_bootstrap_nodes      // Initial DHT bootstrap nodes
    // Format: "host:port,host:port,..."
proxy_hostname           // Proxy hostname
proxy_username           // Proxy username
proxy_password           // Proxy password
i2p_hostname             // I2P SAM bridge hostname
peer_fingerprint         // 2-char peer ID prefix
```

---

### 5. File & Storage

**File**: `include/libtorrent/file_storage.hpp`

#### class `file_storage`
Describes file layout within a torrent.

```cpp
class file_storage {
public:
    // File Information
    int num_files() const;
    std::int64_t total_size() const;
    
    // File Access
    std::string file_path(file_index_t index, std::string const& save_path = "") const;
    std::string file_name(file_index_t index) const;
    std::int64_t file_size(file_index_t index) const;
    std::int64_t file_offset(file_index_t index) const;
    file_flags_t file_flags(file_index_t index) const;
    sha1_hash hash(file_index_t index) const;
    std::string symlink(file_index_t index) const;
    time_t mtime(file_index_t index) const;
    
    // Piece Mapping
    peer_request map_file(file_index_t file, std::int64_t offset, int size) const;
    
    // File Operations
    void add_file(std::string const& path, std::int64_t size, file_flags_t flags = {});
    void rename_file(file_index_t index, std::string const& new_filename);
    void set_piece_length(int size);
    int piece_length() const;
    int num_pieces() const;
    
    // Iteration
    file_index_t begin() const;
    file_index_t end() const;
};
```

#### File Flags
```cpp
enum file_flags_t {
    flag_pad_file = 0x1,      // Padding file
    flag_hidden = 0x2,        // Hidden attribute
    flag_executable = 0x4,    // Executable
    flag_symlink = 0x8        // Symbolic link
};
```

**File**: `include/libtorrent/storage_defs.hpp`

#### Storage Mode
```cpp
enum class storage_mode_t : std::uint8_t {
    storage_mode_allocate = 0,  // Allocate files on add
    storage_mode_sparse = 1     // Sparse allocation
};
```

#### Storage Allocation
```cpp
enum class allocation_mode_t : std::uint8_t {
    sparse,          // Sparse files
    allocate         // Pre-allocate full size
};
```

---

### 6. Peer Management

**File**: `include/libtorrent/peer_info.hpp`

#### struct `peer_info`
Information about a connected peer.

```cpp
struct peer_info {
    // Connection flags
    enum flags_t {
        interesting = 0x1,        // We're interested
        choked = 0x2,            // We're choked
        remote_interested = 0x4,  // Peer is interested
        remote_choked = 0x8,      // Peer is choked
        support_extensions = 0x10, // Supports extensions
        outgoing_connection = 0x20, // Outgoing connection
        local_connection = 0x40,   // Local network
        handshake = 0x80,         // In handshake
        connecting = 0x100,       // Connecting
        on_parole = 0x200,        // On parole
        seed = 0x400,             // Peer is seed
        optimistic_unchoke = 0x800, // Optimistically unchoked
        snubbed = 0x1000,         // Snubbed peer
        upload_only = 0x2000,     // Upload-only mode
        endgame_mode = 0x4000,    // In endgame mode
        holepunched = 0x8000,     // Hole-punched
        i2p_socket = 0x10000,     // I2P connection
        utp_socket = 0x20000,     // uTP connection
        ssl_socket = 0x40000,     // SSL connection
        rc4_encrypted = 0x80000,  // RC4 encrypted
        plaintext_encrypted = 0x100000 // Plaintext header
    };
    
    // Source flags
    enum source_t {
        tracker = 0x1,
        dht = 0x2,
        pex = 0x4,
        lsd = 0x8,
        resume_data = 0x10,
        incoming = 0x20
    };
    
    // Peer Information
    tcp::endpoint ip;             // IP address and port
    peer_id pid;                  // 20-byte peer ID
    client_type_t client;         // Client software
    flags_t flags;                // Status flags
    source_t source;              // Where peer came from
    
    // Transfer Statistics
    int up_speed;                 // Upload rate (bytes/sec)
    int down_speed;               // Download rate
    int payload_up_speed;         // Payload upload rate
    int payload_down_speed;       // Payload download rate
    std::int64_t total_download;  // Total downloaded
    std::int64_t total_upload;    // Total uploaded
    
    // Pieces
    typed_bitfield<piece_index_t> pieces; // Pieces peer has
    int num_pieces;               // Number of pieces
    
    // Requests
    int download_queue_length;    // Queued block requests
    int target_dl_queue_length;   // Target queue length
    int upload_queue_length;      // Upload queue length
    int downloading_piece_index;  // Currently downloading piece
    int downloading_block_index;  // Currently downloading block
    int downloading_progress;     // Block progress (bytes)
    int downloading_total;        // Block size
    
    // Performance
    std::int64_t pending_disk_bytes; // Pending disk bytes
    int send_buffer_size;         // Send buffer bytes
    int used_send_buffer;         // Used send buffer
    int receive_buffer_size;      // Receive buffer size
    int used_receive_buffer;      // Used receive buffer
    int queue_bytes;              // Queued bytes
    
    // Timing
    int last_request;             // Seconds since last request
    int last_active;              // Seconds since last active
    time_duration download_rate_peak; // Peak download rate
    time_duration upload_rate_peak;   // Peak upload rate
    
    // Round-trip time
    int rtt;                      // RTT in milliseconds
    
    // Country
    char country[2];              // 2-letter country code
    
    // Connection type
    connection_type_t connection_type;
    
    // Remote endpoint (for proxy)
    tcp::endpoint remote_dl_endpoint;
    
    // Local endpoint
    tcp::endpoint local_endpoint;
    
    // Progress
    float progress;               // Download progress 0-1
    int progress_ppm;             // Progress in parts per million
};
```

#### Peer Connection Interface
```cpp
struct bt_peer_connection_handle {
    bool is_valid() const;
    bool packet_finished() const;
    bool support_extensions() const;
    
    // Suggest/Have
    void send_have(piece_index_t piece);
    void send_suggest(piece_index_t piece);
    
    // DHT port
    void send_dht_port(int port);
};
```

---

### 7. Tracker Management

**File**: `include/libtorrent/announce_entry.hpp`

#### struct `announce_entry`
Information about a tracker.

```cpp
struct announce_entry {
    announce_entry(std::string const& url);
    
    std::string url;              // Tracker URL
    std::string trackerid;        // Tracker ID
    std::string message;          // Last tracker message
    error_code last_error;        // Last error
    
    // Timing
    time_point next_announce;     // Next announce time
    time_point min_announce;      // Earliest next announce
    
    // Tier
    std::uint8_t tier = 0;        // Tracker tier
    std::uint8_t fail_limit = 0;  // Fail limit before next tier
    std::uint8_t fails = 0;       // Current fail count
    
    // Source
    std::uint8_t source:4;        // Where tracker came from
    
    // Verification
    bool verified:1;              // Working tracker
    
    // Update times
    bool updating:1;              // Currently updating
    bool start_sent:1;            // Sent 'started' event
    bool complete_sent:1;         // Sent 'completed' event
    
    // Send stats
    bool send_stats:1;            // Include stats in announce
    
    // Actions
    void reset();
    bool will_announce(time_point now) const;
    bool can_announce(time_point now, bool is_seed, std::uint8_t fail_limit) const;
    bool is_working() const;
    void trim();
};
```

#### Tracker Endpoints
```cpp
struct announce_endpoint {
    tcp::endpoint local_endpoint; // Local endpoint
    
    // Timing
    time_point next_announce;     // Next announce
    time_point min_announce;      // Min announce time
    
    // Scrape
    int scrape_incomplete = -1;   // Incomplete peers
    int scrape_complete = -1;     // Complete peers
    int scrape_downloaded = -1;   // Times downloaded
    
    // Tier/Fails
    std::uint8_t tier = 0;
    std::uint8_t fail_limit = 0;
    std::uint8_t fails = 0;
    
    // State
    bool updating:1;
    bool start_sent:1;
    bool complete_sent:1;
    bool send_stats:1;
    
    error_code last_error;
    std::string message;
};
```

---

### 8. DHT Operations

**File**: `include/libtorrent/kademlia/dht_state.hpp`

#### struct `dht_state`
DHT routing table state for persistence.

```cpp
struct dht_state {
    node_id nid;                          // Our node ID
    std::vector<udp::endpoint> nodes;     // Bootstrap nodes
    std::vector<udp::endpoint> nodes6;    // IPv6 bootstrap nodes
};
```

**File**: `include/libtorrent/kademlia/dht_storage.hpp`

#### Immutable DHT Item
```cpp
// Get immutable item
session.dht_get_item(sha1_hash target);

// Put immutable item  
session.dht_put_item(entry data);
```

#### Mutable DHT Item
```cpp
// Get mutable item
session.dht_get_item(std::array<char, 32> public_key, std::string salt);

// Put mutable item
using dht_put_item_cb = std::function<void(
    entry& item,                          // Item to put
    std::array<char,64>& signature,       // Signature output
    std::int64_t& seq,                    // Sequence number
    std::string const& salt)>;            // Salt

session.dht_put_item(std::array<char, 32> public_key,
                     dht_put_item_cb cb,
                     std::string salt);
```

#### DHT Announce
```cpp
enum class announce_flags_t : std::uint8_t {
    none = 0,
    seed = 1,           // Announce as seed
    implied_port = 2    // Use source port
};

session.dht_announce(sha1_hash info_hash, int port = 0, 
                     announce_flags_t flags = {});
```

---

### 9. Network & Connectivity

**File**: `include/libtorrent/address.hpp`

#### IP Address Types
```cpp
using address = boost::asio::ip::address;
using address_v4 = boost::asio::ip::address_v4;
using address_v6 = boost::asio::ip::address_v6;

// TCP/UDP endpoints
using tcp::endpoint;
using udp::endpoint;
```

**File**: `include/libtorrent/ip_filter.hpp`

#### class `ip_filter`
Filter IP address ranges.

```cpp
class ip_filter {
public:
    enum access_flags {
        blocked = 1  // Blocked IP
    };
    
    // Add IPv4 range
    void add_rule(address_v4 first, address_v4 last, std::uint32_t flags);
    
    // Add IPv6 range
    void add_rule(address_v6 first, address_v6 last, std::uint32_t flags);
    
    // Check access
    std::uint32_t access(address const& addr) const;
    
    // Export filter
    using filter_tuple_t = std::tuple<address, address, std::uint32_t>;
    std::vector<filter_tuple_t> export_filter() const;
};
```

**File**: `include/libtorrent/proxy_settings.hpp` (in settings_pack.hpp)

#### Proxy Settings
```cpp
enum class proxy_type_t : std::uint8_t {
    none,
    socks4,
    socks5,
    socks5_pw,    // SOCKS5 with password
    http,
    http_pw,      // HTTP with password
    i2p_proxy
};

struct proxy_settings {
    std::string hostname;
    std::uint16_t port = 0;
    std::string username;
    std::string password;
    proxy_type_t type = proxy_type_t::none;
    bool proxy_hostnames = true;
    bool proxy_peer_connections = true;
    bool proxy_tracker_connections = true;
};
```

---

### 10. Data Structures

#### struct `add_torrent_params`
**File**: `include/libtorrent/add_torrent_params.hpp`

```cpp
struct add_torrent_params {
    // Version
    int version = LIBTORRENT_VERSION_NUM;
    
    // Torrent source (provide one of these)
    std::shared_ptr<torrent_info> ti;     // Parsed .torrent
    info_hash_t info_hashes;              // Info-hash(es)
    char const* name = nullptr;           // Display name
    
    // Save location
    std::string save_path;                // REQUIRED: Where to save
    
    // Trackers and web seeds
    std::vector<std::string> trackers;
    std::vector<std::string> tracker_tiers;
    std::vector<std::string> dht_nodes;
    std::vector<std::string> url_seeds;
    std::vector<std::string> http_seeds;
    
    // Peers
    std::vector<tcp::endpoint> peers;
    std::vector<tcp::endpoint> banned_peers;
    
    // Resume data
    std::vector<char> resume_data;
    
    // Priorities
    std::vector<download_priority_t> file_priorities;
    std::vector<download_priority_t> piece_priorities;
    std::vector<std::uint8_t> verified_leaf_hashes;
    
    // Merkle tree (BEP52 - v2 torrents)
    std::vector<std::vector<sha256_hash>> merkle_trees;
    std::vector<std::vector<bool>> verified_pieces;
    std::vector<sha256_hash> merkle_tree_mask;
    
    // Limits
    int max_uploads = -1;
    int max_connections = -1;
    int upload_limit = -1;
    int download_limit = -1;
    
    // Flags
    torrent_flags_t flags = torrent_flags::default_flags;
    
    // User data
    client_data_t userdata;
    
    // Renamed files
    std::vector<std::pair<file_index_t, std::string>> renamed_files;
    
    // Info dict (raw)
    std::vector<char> info_dict;
};
```

#### struct `torrent_status`
**File**: `include/libtorrent/torrent_status.hpp`

```cpp
struct torrent_status {
    enum state_t {
        checking_files,           // Checking existing files
        downloading_metadata,     // Downloading .torrent from peers
        downloading,              // Downloading
        finished,                 // Finished downloading
        seeding,                  // Seeding
        checking_resume_data      // Checking resume data
    };
    
    // Handle
    torrent_handle handle;
    
    // Error state
    error_code errc;
    std::string error_file;
    
    // State
    state_t state;
    
    // Progress
    std::int64_t total_done;           // Bytes downloaded and verified
    std::int64_t total_wanted_done;    // Wanted bytes done
    std::int64_t total_wanted;         // Total wanted bytes
    std::int64_t total_download;       // Payload bytes downloaded
    std::int64_t total_upload;         // Payload bytes uploaded
    std::int64_t total_payload_download; // Payload download
    std::int64_t total_payload_upload;   // Payload upload
    std::int64_t total_failed_bytes;   // Failed hash bytes
    std::int64_t total_redundant_bytes; // Redundant bytes
    std::int64_t all_time_upload;      // Session total upload
    std::int64_t all_time_download;    // Session total download
    time_t added_time;                 // When added
    time_t completed_time;             // When completed
    time_t last_seen_complete;         // Last seen complete
    
    // Rates
    int download_rate;                 // Current download rate (bytes/sec)
    int upload_rate;                   // Current upload rate
    int download_payload_rate;         // Payload download rate
    int upload_payload_rate;           // Payload upload rate
    
    // Seeds and peers
    int num_seeds;                     // Connected seeds
    int num_peers;                     // Connected peers
    int num_complete;                  // Complete in swarm (-1 = unknown)
    int num_incomplete;                // Incomplete in swarm
    int list_seeds;                    // Seeds in peer list
    int list_peers;                    // Peers in peer list
    int connect_candidates;            // Connectable peers
    
    // Pieces
    typed_bitfield<piece_index_t> pieces;  // Downloaded pieces
    typed_bitfield<piece_index_t> verified_pieces; // Verified pieces (seed mode)
    int num_pieces;                    // Total pieces
    float distributed_full_copies;     // Distributed copies (availability)
    int distributed_fraction;          // Fractional copies
    float distributed_copies;          // Total distributed copies
    
    // Block size
    int block_size;                    // Block size in bytes
    
    // Connections
    int num_uploads;                   // Peers we're uploading to
    int num_connections;               // Total connections
    int uploads_limit;                 // Upload slots limit
    int connections_limit;             // Connections limit
    
    // Bandwidth queues
    int up_bandwidth_queue;            // Queued upload bytes
    int down_bandwidth_queue;          // Queued download bytes
    
    // Time
    int active_duration;               // Active seconds
    int finished_duration;             // Finished seconds
    int seeding_duration;              // Seeding seconds
    
    // Priority
    queue_position_t queue_position;   // Queue position
    
    // Seed rank
    int seed_rank;                     // Seed priority
    
    // Scrape
    int last_scrape;                   // Seconds since scrape
    
    // Download queue
    int has_incoming;                  // Has incoming connection
    
    // Seed mode
    int seed_mode;                     // In seed mode
    
    // Upload mode
    int upload_mode;                   // In upload mode
    
    // Share mode
    int share_mode;                    // In share mode
    
    // Super seeding
    int super_seeding;                 // Super seeding
    
    // Paused
    int paused;                        // Is paused
    
    // Auto managed
    int auto_managed;                  // Auto managed
    
    // Sequential
    int sequential_download;           // Sequential download
    
    // Seed
    int is_seeding;                    // Is seed
    
    // Finished
    int is_finished;                   // Has all pieces
    
    // Metadata
    int has_metadata;                  // Has metadata
    
    // Announce
    time_point next_announce;          // Next tracker announce
    time_point current_tracker;        // Current tracker URL
    
    // Moving storage
    int moving_storage;                // Moving storage
    
    // Announcing
    int announcing_to_trackers;        // Announcing
    int announcing_to_lsd;             // LSD announcing
    int announcing_to_dht;             // DHT announcing
    
    // Torrent file
    std::shared_ptr<const torrent_info> torrent_file;
    
    // Info hash
    info_hash_t info_hash;
    
    // Name
    std::string name;
    
    // Save path
    std::string save_path;
    
    // Flags
    torrent_flags_t flags;
    
    // Piece size
    int piece_length;
};
```

#### struct `session_status`
**File**: `include/libtorrent/session_status.hpp`

```cpp
struct session_status {
    bool has_incoming_connections;
    
    // Upload/download rates
    int upload_rate;
    int download_rate;
    std::int64_t total_download;
    std::int64_t total_upload;
    
    // Payload rates
    int payload_upload_rate;
    int payload_download_rate;
    std::int64_t total_payload_download;
    std::int64_t total_payload_upload;
    
    // IP overhead
    int ip_overhead_upload_rate;
    int ip_overhead_download_rate;
    std::int64_t total_ip_overhead_download;
    std::int64_t total_ip_overhead_upload;
    
    // DHT
    int dht_upload_rate;
    int dht_download_rate;
    std::int64_t total_dht_download;
    std::int64_t total_dht_upload;
    
    // Tracker
    int tracker_upload_rate;
    int tracker_download_rate;
    std::int64_t total_tracker_download;
    std::int64_t total_tracker_upload;
    
    // Failed/redundant
    std::int64_t total_redundant_bytes;
    std::int64_t total_failed_bytes;
    
    // Peers
    int num_peers;
    int num_unchoked;
    int allowed_upload_slots;
    
    // Bandwidth queue
    int up_bandwidth_queue;
    int down_bandwidth_queue;
    int up_bandwidth_bytes_queue;
    int down_bandwidth_bytes_queue;
    
    // Choking
    int optimistic_unchoke_counter;
    int unchoke_counter;
    
    // DHT
    int dht_nodes;
    int dht_node_cache;
    int dht_torrents;
    std::int64_t dht_global_nodes;
    
    // UTP
    int utp_stats_num_idle;
    int utp_stats_num_syn_sent;
    int utp_stats_num_connected;
    int utp_stats_num_fin_sent;
    int utp_stats_num_close_wait;
    
    // Disk
    int disk_write_queue;
    int disk_read_queue;
};
```

---

## Enumerations & Constants

### Torrent Flags
**File**: `include/libtorrent/torrent_flags.hpp`

```cpp
enum class torrent_flags : std::uint64_t {
    seed_mode                   = 0x1,
    upload_mode                 = 0x2,
    share_mode                  = 0x4,
    apply_ip_filter             = 0x8,
    paused                      = 0x10,
    auto_managed                = 0x20,
    duplicate_is_error          = 0x40,
    update_subscribe            = 0x80,
    super_seeding               = 0x100,
    sequential_download         = 0x200,
    stop_when_ready             = 0x400,
    override_trackers           = 0x800,
    override_web_seeds          = 0x1000,
    need_save_resume            = 0x2000,
    disable_dht                 = 0x4000,
    disable_lsd                 = 0x8000,
    disable_pex                 = 0x10000,
    no_verify_files             = 0x20000,
    i2p_torrent                 = 0x40000,
    
    default_flags = update_subscribe | auto_managed | paused | apply_ip_filter,
    
    all = 0xffffffffffffffffULL
};
```

### Download Priority
**File**: `include/libtorrent/download_priority.hpp`

```cpp
enum class download_priority_t : std::uint8_t {
    dont_download = 0,
    default_priority = 4,
    low = 1,
    top_priority = 7
};
```

### Remove Flags
```cpp
enum class remove_flags_t : std::uint8_t {
    none = 0,
    delete_files = 1,
    delete_partfile = 2
};
```

### Resume Data Flags
```cpp
enum class resume_data_flags_t : std::uint8_t {
    none = 0,
    flush_disk_cache = 1,
    save_info_dict = 2,
    only_if_modified = 4,
    if_counters_changed = 8,
    if_download_progress = 16,
    if_config_changed = 32,
    if_state_changed = 64,
    if_metadata_changed = 128
};
```

### Status Flags
```cpp
enum class status_flags_t : std::uint32_t {
    query_distributed_copies    = 1,
    query_accurate_download_counters = 2,
    query_last_seen_complete    = 4,
    query_pieces                = 8,
    query_verified_pieces       = 16,
    query_torrent_file          = 32,
    query_name                  = 64,
    query_save_path             = 128,
    
    all = 0xffffffff
};
```

### Pause Flags
```cpp
enum class pause_flags_t : std::uint8_t {
    graceful_pause = 1  // Finish in-progress requests
};
```

### Deadline Flags
```cpp
enum class deadline_flags_t : std::uint8_t {
    alert_when_available = 1
};
```

### Reannounce Flags
```cpp
enum class reannounce_flags_t : std::uint8_t {
    ignore_min_interval = 1
};
```

### Add Piece Flags
```cpp
enum class add_piece_flags_t : std::uint8_t {
    overwrite_existing = 1
};
```

### File Progress Flags
```cpp
enum class file_progress_flags_t : std::uint8_t {
    piece_granularity = 1
};
```

### Save State Flags
```cpp
enum class save_state_flags_t : std::uint32_t {
    save_settings          = 0x001,
    save_dht_settings      = 0x002,
    save_dht_state         = 0x004,
    save_encryption_settings = 0x020,
    save_peer_proxy        = 0x040,
    save_web_proxy         = 0x080,
    save_tracker_proxy     = 0x100,
    save_i2p_proxy         = 0x200,
    
    save_dht               = save_dht_settings | save_dht_state,
    save_proxy             = save_peer_proxy | save_web_proxy | save_tracker_proxy | save_i2p_proxy,
    
    all = 0xffffffff
};
```

### Port Mapping Protocol
```cpp
enum class portmap_protocol : std::uint8_t {
    none = 0,
    udp = 1,
    tcp = 2
};

enum class portmap_transport : std::uint8_t {
    natpmp = 0,
    upnp = 1
};
```

### Peer Source
```cpp
enum class peer_source_flags_t : std::uint8_t {
    tracker = 0x1,
    dht = 0x2,
    pex = 0x4,
    lsd = 0x8,
    resume_data = 0x10,
    incoming = 0x20
};
```

### PEX Flags
```cpp
enum class pex_flags_t : std::uint8_t {
    encryption = 0x1,
    seed = 0x2,
    utp = 0x4,
    holepunch = 0x8,
    i2p = 0x10
};
```

---

## Utility Functions

### Magnet URIs
**File**: `include/libtorrent/magnet_uri.hpp`

```cpp
// Generate magnet link from torrent
std::string make_magnet_uri(torrent_handle const& handle);
std::string make_magnet_uri(torrent_info const& info);

// Parse magnet link
add_torrent_params parse_magnet_uri(std::string const& uri);
add_torrent_params parse_magnet_uri(std::string const& uri, error_code& ec);
```

### Torrent File Loading
**File**: `include/libtorrent/load_torrent.hpp`

```cpp
// Load from file
add_torrent_params load_torrent_file(std::string const& filename);
add_torrent_params load_torrent_file(std::string const& filename, error_code& ec);

// Load from buffer
add_torrent_params load_torrent_buffer(span<char const> buffer);
add_torrent_params load_torrent_buffer(span<char const> buffer, error_code& ec);

// Load from parsed bencode
add_torrent_params load_torrent_parsed(bdecode_node const& torrent_file);
add_torrent_params load_torrent_parsed(bdecode_node const& torrent_file, error_code& ec);
```

### Creating Torrents
**File**: `include/libtorrent/create_torrent.hpp`

```cpp
class create_torrent {
public:
    enum flags_t {
        optimize_alignment = 1,
        merkle = 2,
        modification_time = 4,
        symlinks = 8,
        canonical_files = 16,
        canonical_files_no_tail_padding = 32,
        v2_only = 64,
        v1_only = 128
    };
    
    create_torrent(file_storage& fs, int piece_size = 0, 
                   int pad_file_limit = -1, flags_t flags = optimize_alignment);
    create_torrent(torrent_info const& ti);
    
    entry generate() const;
    
    void add_tracker(std::string const& url, int tier = 0);
    void set_comment(char const* str);
    void set_creator(char const* str);
    void set_hash(piece_index_t index, sha1_hash const& h);
    void set_hash2(file_index_t file, piece_index_t piece, sha256_hash const& h);
    void set_file_hash(file_index_t index, sha1_hash const& h);
    void add_url_seed(std::string const& url);
    void add_http_seed(std::string const& url);
    void add_node(std::pair<std::string, int> const& node);
    void add_collection(std::string const& c);
    void set_priv(bool p);
    void set_root_cert(std::string const& cert);
    
    int num_pieces() const;
    int piece_length() const;
    int piece_size(piece_index_t index) const;
    bool priv() const;
};
```

### Resume Data
**File**: `include/libtorrent/write_resume_data.hpp`, `include/libtorrent/read_resume_data.hpp`

```cpp
// Write resume data to bencode
entry write_resume_data(add_torrent_params const& atp);
std::vector<char> write_resume_data_buf(add_torrent_params const& atp);

// Read resume data from bencode
add_torrent_params read_resume_data(bdecode_node const& rd);
add_torrent_params read_resume_data(bdecode_node const& rd, error_code& ec);
add_torrent_params read_resume_data(span<char const> buf);
add_torrent_params read_resume_data(span<char const> buf, error_code& ec);
```

### Version Information
**File**: `include/libtorrent/version.hpp`

```cpp
#define LIBTORRENT_VERSION_MAJOR 2
#define LIBTORRENT_VERSION_MINOR 0
#define LIBTORRENT_VERSION_TINY 11

#define LIBTORRENT_VERSION "2.0.11"
#define LIBTORRENT_REVISION "163d36465"

constexpr char const* version();
constexpr std::uint32_t version_num();
```

---

## Summary

This specification documents the complete public API of libtorrent version 2.0.11, comprising:

- **272 header files** organized under `include/libtorrent/`
- **50+ major classes and structures**
- **100+ core public methods**
- **30+ alert types** for event notifications
- **200+ configuration settings** via `settings_pack`
- Support for **BitTorrent v1 & v2**, DHT, UPnP, NAT-PMP, encryption, I2P, SOCKS proxies, and more

### Key API Entry Points

1. **session** - Create and manage torrents
2. **torrent_handle** - Control individual torrents
3. **add_torrent_params** - Configure new torrents
4. **settings_pack** - Configure session behavior
5. **alert system** - Monitor events and progress
6. **torrent_status** - Query torrent state
7. **peer_info** - Inspect peer connections

### Common Workflow

```cpp
// 1. Create session
lt::session ses(lt::session_params());

// 2. Configure
lt::settings_pack pack;
pack.set_int(lt::settings_pack::alert_mask, lt::alert::all_categories);
ses.apply_settings(pack);

// 3. Add torrent
lt::add_torrent_params atp;
atp.save_path = "/downloads";
atp.ti = std::make_shared<lt::torrent_info>("file.torrent");
lt::torrent_handle h = ses.add_torrent(atp);

// 4. Monitor
std::vector<lt::alert*> alerts;
ses.pop_alerts(&alerts);
for (auto a : alerts) {
    // Handle alerts
}

// 5. Control
h.pause();
h.resume();

// 6. Query status
lt::torrent_status st = h.status();

// 7. Save state
h.save_resume_data(lt::torrent_handle::flush_disk_cache);
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-03-12  
**libtorrent Version**: 2.0.11 (commit: 163d36465fec31070c7717efb759507a177ec8a6)
