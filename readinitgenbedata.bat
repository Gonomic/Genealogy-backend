docker run --rm --volumes-from GENBE01 -v d:/Frans/Development/Gen/Genealogy-backend/xfergenbedata:/xfergenbedata ubuntu bash -c "cd /var/lib/mysql && tar cvf /xfergenbedata/initgenbedata.tar ."
