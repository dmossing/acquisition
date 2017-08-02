classdef AndorSrc
    properties
        hndl
        previewing
    end
    methods
        function src = genAndorSrc()
            [rc] = AT_InitialiseLibrary();
            AT_CheckError(rc);
            [rc,hndl] = AT_Open(0);
            AT_CheckError(rc);
            src.hndl = hndl;
            src.setEnumString('CycleMode','Continuous')
            src.setEnumString('TriggerMode','Internal')
            src.setEnumString('SimplePreAmpGainControl','16-bit (low noise & high well capacity)')
            src.setEnumString('PixelEncoding','Mono16')
        end
        function [height,width] = getSize(src)
            height = src.getInt('AOIHeight');
            width = src.getInt('AOIWidth');
        end
        function set(src,paramName,paramVal)
            if isstr(paramVal)
                rc = AT_SetEnumString(src.hndl,paramName,paramVal);
                AT_CheckWarning(rc);
            elseif isinteger(paramVal)
                rc = AT_SetInt(src.hndl,paramName,paramVal);
                AT_CheckWarning(rc);
            elseif isfloat(paramVal)
                rc = AT_SetFloat(src.hndl,paramName,paramVal);
                AT_CheckWarning(rc);
            elseif isboolean(paramVal)
                rc = AT_SetBool(src.hndl,paramName,paramVal);
                AT_CheckWarning(rc);
            end
        end
        %         function setEnumString(src,paramName,paramVal)
        %             rc = AT_SetEnumString(src.hndl,paramName,string(paramVal));
        %             AT_CheckWarning(rc);
        %         end
        %         function setInt(src,paramName,paramVal)
        %             rc = AT_SetInt(src.hndl,paramName,int8(paramVal));
        %             AT_CheckWarning(rc);
        %         end
        %         function setFloat(src,paramName,paramVal)
        %             rc = AT_SetFloat(src.hndl,paramName,double(paramVal));
        %             AT_CheckWarning(rc);
        %         end
        %         function setBool(src,paramName,paramVal)
        %             rc = AT_SetBool(src.hndl,paramName,boolean(paramVal));
        %             AT_CheckWarning(rc);
        %         end
        function paramVal = getEnumString(src,paramName)
            [rc,paramVal] = AT_GetEnumString(src.hndl,paramName);
            AT_CheckWarning(rc);
        end
        function paramVal = getInt(src,paramName)
            [rc,paramVal] = AT_GetInt(src.hndl,paramName);
            AT_CheckWarning(rc);
        end
        function paramVal = getFloat(src,paramName)
            [rc,paramVal] = AT_GetFloat(src.hndl,paramName);
            AT_CheckWarning(rc);
        end
        function paramVal = getBool(src,paramName)
            [rc,paramVal] = AT_GetBool(src.hndl,paramName);
            AT_CheckWarning(rc);
        end
        function preview(src,h)
            src.previewing = true;
            [rc] = AT_Command(hndl,'AcquisitionStart');
            AT_CheckWarning(rc);
            buf2 = zeros(height,width);
            while src.previewing
                [rc] = AT_QueueBuffer(hndl,imagesize);
                AT_CheckWarning(rc);
                [rc,buf] = AT_WaitBuffer(hndl,1000);
                AT_CheckWarning(rc);
                [rc,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
                AT_CheckWarning(rc);
                set(h,'CData',buf2)
            end
        end
    end
end