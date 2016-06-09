# (c) 2012-2016 Inria by David Margery (david.margery@inria.fr) in the context of the Grid'5000 project
# Licenced under the CeCILL B licence.

root.sites.each do |site| 
  begin
    puts "#{site["uid"].capitalize} &  &  &  &  &  &  \\\\"
    site.clusters.each do |cluster|
      date = cluster["created_at"].split(" ")[3]
      cluster_size = cluster.nodes.length
      node = cluster.nodes[0]
      arch = node["architecture"]
      nb_cpu = arch["smp_size"]
      nb_core = arch["smt_size"]/nb_cpu
      cpu_type = arch["platform_type"]
      cpu_speed = node["processor"]["clock_speed"].to_i/(10E8)
      memory = (node["main_memory"]["ram_size"].to_i.to_f / (1024**3).to_f).round
      storages = {}
      node['storage_devices'].each do |device|
        unless device['storage'].nil?
          storages[device['storage']].nil? ? storages[device['storage']] = [(device['size'].to_i / 1024**3).round] : storages[device['storage']] += [(device['size'].to_i / 1024**3).round]
        end
      end
      cluster_storages = ''
        storages.each do |t, s|
          sizes = Hash.new(0)
          s.each { |v| sizes.store(v, sizes[v]+1) }
          sizes.each do |size, nb|
            if nb > 1
              cluster_storages += " #{nb}x#{size}GB #{t},"
            else
              cluster_storages += " #{size}GB #{t},"
            end
          end # each size
        end # each storage
      cluster_storages = cluster_storages[0..-2]
      ib = ""
      eth10g_count = 0
      node["network_adapters"].each do |d|;
        if d['mounted'] && d['device'] =~ /ib/;
          ib_rate = (d["rate"].to_i / 10E8).round
          ib_type = ""
          case ib_rate
          when 0..10
            ib_type = "SDR"
          when 10.1..20
            ib_type = "DDR"
          when 20.1..40
            ib_type = "QDR"
          when 40.0..56
            ib_type = "FDR"
          when 56.1..100
            ib_type = "EDR"
          else
            ib_type = ""
          end
          ib = "IB#{ib_rate}G #{ib_type}"
        elsif d['mountable'] && d['device'] =~ /eth/
          if d['rate'] >= 10*10E8
            eth10g_count += 1
          end
        end
      end
      eth10g = ""
      if eth10g_count > 0
        eth10g = " #{eth10g_count}x10G"
      end
      node['gpu']  ||= {}
      gpu_model = node['gpu']['gpu_model']
      gpu_count = node['gpu']['gpu_count'] || "0"
      gpu = ""
      if gpu_count.to_i >= 1
        gpu = "#{gpu_count}x#{gpu_model}"
      end
      puts "#{cluster["uid"]} (#{date}) & #{cluster_size} & #{nb_cpu}x#{nb_core}cores @#{cpu_speed}Ghz & #{memory}Gb & #{cluster_storages} & #{gpu} & #{ib}#{eth10g} \\\\"
    end
  rescue Restfully::HTTP::ServerError => e
    puts "Could not access information from #{site["uid"]}"
  end
end

