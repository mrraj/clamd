require 'socket'
require 'clamd/commands'

module Clamd
  module SocketManager
    include Commands

    def open_socket(host, port)
      TCPSocket.open(host, port)
    end

    def close_socket(socket)
      socket.close
    end
    
    def read_socket(socket, command)
      socket.recv(clamd_response_size(command)).gsub(/(\u0000)|(\n)/, "").strip
    end

    def write_socket(socket, command, path)
      if path && command != COMMAND[:instream]
        socket.write("#{command} #{path}")
      else
        socket.write(command)
      end
      stream_to_clamd(socket, path) if command == COMMAND[:instream]
    end

    def clamd_response_size(command)
      case command
      when COMMAND[:ping]
        4
      when COMMAND[:reload]
        9
      when COMMAND[:shutdown]
        1
      else
        1024
      end
    end
    
    def stream_to_clamd(socket, path)
      begin
        file = File.open(path, "rb")
        bytes = file.read(chunk_size)

        while bytes
          write_chunk(socket, bytes)
          bytes = file.read(chunk_size)
        end
        stop_streaming(socket)
      ensure
        file.close if file
      end
    end

    def write_chunk(socket, chunk)
      socket.write([chunk.size].pack("N"))
      socket.write(chunk)
    end

    def stop_streaming(socket)
      socket.write([0].pack("N"))
    end
  end
end