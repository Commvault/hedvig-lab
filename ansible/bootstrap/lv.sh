#!/bin/bash -x 

lvextend -L+10G /dev/mapper/rootvg-rootlv
lvextend -L+10G /dev/mapper/rootvg-usrlv
lvextend -L+10G /dev/mapper/rootvg-varlv
lvextend -L+3G /dev/mapper/rootvg-tmplv
resize2fs /dev/mapper/rootvg-rootlv
resize2fs /dev/mapper/rootvg-usrlv
resize2fs /dev/mapper/rootvg-optlv
resize2fs /dev/mapper/rootvg-homelv
resize2fs /dev/mapper/rootvg-tmplv
resize2fs /dev/mapper/rootvg-varlv
