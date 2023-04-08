classdef SerialDeviceStatuses
    %SERIALDEVICESTATUSES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        status (1,1) string;
    end
    
    methods
        function this = SerialDeviceStatuses(status)
            this.status = status;
        end
    end

    enumeration
        OPEN("open"), CLOSED("closed");
    end
end

