#ifndef __COMMUNICATION_HPP__
#define __COMMUNICATION_HPP__

#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <memory>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <winsock2.h>
#include <windows.h>
#include <ws2tcpip.h>

#pragma comment(lib, "ws2_32.lib")

namespace communication_sdk {

// 数据包类型
enum class PacketType : uint32_t {
    Unknown,  // 未知类型
    Message,  // 消息类型
    Data,     // 数据类型
    Command,  // 命令类型
};

// 数据包头
struct PacketHeader {
    PacketType type;        // 数据包类型
    uint32_t length;        // 数据包长度（不包括头部）
    uint32_t sequence_num;  // 序列号（可选）
};

// 数据包
struct Packet {
    PacketHeader header;    // 数据包头
    std::vector<char> data; // 数据
};

// 命名管道
class NamedPipe {
public:
    NamedPipe() : pipe_handle_(INVALID_HANDLE_VALUE) {}
    ~NamedPipe() { Close(); }

    bool Create(const std::wstring& pipe_name) {
        pipe_handle_ = CreateNamedPipeW(
            pipe_name.c_str(),
            PIPE_ACCESS_DUPLEX,
            PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
            PIPE_UNLIMITED_INSTANCES,
            1024,
            1024,
            NMPWAIT_USE_DEFAULT_WAIT,
            nullptr);
        return pipe_handle_ != INVALID_HANDLE_VALUE;
    }

    bool Connect() {
        if (pipe_handle_ != INVALID_HANDLE_VALUE) {
            if (ConnectNamedPipe(pipe_handle_, nullptr) != FALSE) {
                return true;
            }
        }
        return false;
    }

    bool Write(const Packet& packet) {
        DWORD bytes_written = 0;
        if (WriteFile(pipe_handle_, &packet.header, sizeof(packet.header), &bytes_written, nullptr) &&
            WriteFile(pipe_handle_, packet.data.data(), packet.data.size(), &bytes_written, nullptr)) {
            return true;
        }
        return false;
    }

    bool Read(Packet& packet) {
        DWORD bytes_read = 0;
        if (ReadFile(pipe_handle_, &packet.header, sizeof(packet.header), &bytes_read, nullptr)) {
            packet.data.resize(packet.header.length);
            if (ReadFile(pipe_handle_, packet.data.data(), packet.header.length, &bytes_read, nullptr)) {
                return true;
            }
        }
        return false;
    }

    void Close() {
        if (pipe_handle_ != INVALID_HANDLE_VALUE) {
            DisconnectNamedPipe(pipe_handle_);
            CloseHandle(pipe_handle_);
            pipe_handle_ = INVALID_HANDLE_VALUE;
        }
    }

private:
    HANDLE pipe_handle_;
};

// 匿名管道
class AnonymousPipe {
public:
    AnonymousPipe() : read_pipe_(INVALID_HANDLE_VALUE), write_pipe_(INVALID_HANDLE_VALUE) {}
    ~AnonymousPipe() { Close(); }

    bool Create() {
        SECURITY_ATTRIBUTES sa = { sizeof(sa), nullptr, true };
        if (CreatePipe(&read_pipe_, &write_pipe_, &sa, 0) != FALSE) {
            return true;
        }
        return false;
    }

    bool Write(const Packet& packet) {
        DWORD bytes_written = 0;
        if (WriteFile(write_pipe_, &packet.header, sizeof(packet.header), &bytes_written, nullptr) &&
            WriteFile(write_pipe_, packet.data.data(), packet.data.size(), &bytes_written, nullptr)) {
            return true;
        }
        return false;
    }

    bool Read(Packet& packet) {
        DWORD bytes_read = 0;
        if (ReadFile(read_pipe_, &packet.header, sizeof(packet.header), &bytes_read, nullptr)) {
            packet.data.resize(packet.header.length);
            if (ReadFile(read_pipe_, packet.data.data(), packet.header.length, &bytes_read, nullptr)) {
                return true;
            }
        }
        return false;
    }

    void Close() {
        if (read_pipe_ != INVALID_HANDLE_VALUE) {
            CloseHandle(read_pipe_);
            read_pipe_ = INVALID_HANDLE_VALUE;
        }
        if (write_pipe_ != INVALID_HANDLE_VALUE) {
            CloseHandle(write_pipe_);
            write_pipe_ = INVALID_HANDLE_VALUE;
        }
    }

    HANDLE GetReadHandle() const { return read_pipe_; }
    HANDLE GetWriteHandle() const { return write_pipe_; }

private:
    HANDLE read_pipe_;
    HANDLE write_pipe_;
};

// 共享内存
class SharedMemory {
public:
    SharedMemory() : memory_handle_(INVALID_HANDLE_VALUE), memory_ptr_(nullptr), memory_size_(0) {}
    ~SharedMemory() { Close(); }

    bool Create(const std::wstring& memory_name, uint32_t size) {
        memory_handle_ = CreateFileMappingW(
            INVALID_HANDLE_VALUE,
            nullptr,
            PAGE_READWRITE,
            0,
            size,
            memory_name.c_str());
        if (memory_handle_ != INVALID_HANDLE_VALUE) {
            memory_ptr_ = reinterpret_cast<char*>(MapViewOfFile(memory_handle_, FILE_MAP_WRITE, 0, 0, size));
            memory_size_ = size;
            return true;
        }
        return false;
    }

    bool Open(const std::wstring& memory_name) {
        memory_handle_ = OpenFileMappingW(FILE_MAP_WRITE, FALSE, memory_name.c_str());
        if (memory_handle_ != INVALID_HANDLE_VALUE) {
            memory_ptr_ = reinterpret_cast<char*>(MapViewOfFile(memory_handle_, FILE_MAP_WRITE, 0, 0, 0));
            if (memory_ptr_ != nullptr) {
                memory_size_ = GetFileSize(memory_handle_, nullptr);
                return true;
            }
        }
        return false;
    }

    bool Write(const Packet& packet) {
        if (packet.header.length <= memory_size_) {
            std::memcpy(memory_ptr_, &packet.header, sizeof(packet.header));
            std::memcpy(memory_ptr_ + sizeof(packet.header), packet.data.data(), packet.data.size());
            return true;
        }
        return false;
    }

    bool Read(Packet& packet) {
        std::memcpy(&packet.header, memory_ptr_, sizeof(packet.header));
        packet.data.resize(packet.header.length);
        std::memcpy(packet.data.data(), memory_ptr_ + sizeof(packet.header), packet.header.length);
        return true;
    }

    void Close() {
        if (memory_ptr_ != nullptr) {
            UnmapViewOfFile(memory_ptr_);
            memory_ptr_ = nullptr;
        }
        if (memory_handle_ != INVALID_HANDLE_VALUE) {
            CloseHandle(memory_handle_);
            memory_handle_ = INVALID_HANDLE_VALUE;
        }
        memory_size_ = 0;
    }

private:
    HANDLE memory_handle_;
    char* memory_ptr_;
    uint32_t memory_size_;
};

// Socket 通信
class Socket {
public:
    Socket() : socket_(INVALID_SOCKET) {}
    ~Socket() { Close(); }

    bool Create() {
        socket_ = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        return socket_ != INVALID_SOCKET;
    }

    bool Bind(const std::string& ip, uint16_t port) {
        sockaddr_in addr = { 0 };
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        inet_pton(AF_INET, ip.c_str(), &addr.sin_addr);
        if (bind(socket_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != SOCKET_ERROR) {
            return true;
        }
        return false;
    }

    bool Listen() {
        if (listen(socket_, SOMAXCONN) != SOCKET_ERROR) {
            return true;
        }
        return false;
    }

    bool Accept(Socket& client_socket) {
        SOCKET client = accept(socket_, NULL, NULL);
        if (client != INVALID_SOCKET) {
            client_socket.socket_ = client;
            return true;
        }
        return false;
    }

    bool Connect(const std::string& ip, uint16_t port) {
        sockaddr_in addr = { 0 };
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        inet_pton(AF_INET, ip.c_str(), &addr.sin_addr);
        if (connect(socket_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != SOCKET_ERROR) {
            return true;
        }
        return false;
    }

    bool Write(const Packet& packet) {
        uint32_t packet_length = sizeof(packet.header) + packet.data.size();
        std::vector<char> buffer(packet_length);
        std::memcpy(buffer.data(), &packet.header, sizeof(packet.header));
        std::memcpy(buffer.data() + sizeof(packet.header), packet.data.data(), packet.data.size());
        int result = send(socket_, buffer.data(), packet_length, 0);
        return result != SOCKET_ERROR;
    }

    bool Read(Packet& packet) {
        uint32_t packet_length = 0;
        int result = recv(socket_, reinterpret_cast<char*>(&packet_length), sizeof(packet_length), 0);
        if (result != SOCKET_ERROR && packet_length > 0) {
            packet.header.length = packet_length - sizeof(packet.header);
            packet.data.resize(packet.header.length);
            result = recv(socket_, packet.data.data(), packet.header.length, 0);
            return result != SOCKET_ERROR;
        }
        return false;
    }

    void Close() {
        if (socket_ != INVALID_SOCKET) {
            closesocket(socket_);
            socket_ = INVALID_SOCKET;
        }
    }

private:
    SOCKET socket_;
};

};

#endif // __COMMUNICATION_HPP__