import { useEffect, useState } from "react"
import { fetchTextResource } from "../001_clients_and_managers/002_ResourceLoader"
import { useAppSetting } from "../003_provider/AppSettingProvider"

export type CorpusTextData = {
    "title": string,
    "wavPrefix": string,
    "file": string,
    "file_auth": string,
    "text": string[]
}

export type CorpusDataState = {
    corpusTextData: { [title: string]: CorpusTextData }
    corpusLoaded: boolean
}
export type CorpusDataStateAndMethod = CorpusDataState & {}

export const useCorpusData = (): CorpusDataStateAndMethod => {
    const { applicationSetting } = useAppSetting()
    const textSettings = applicationSetting.applicationSetting.text
    const [corpusTextData, setCorpusTextData] = useState<{ [title: string]: CorpusTextData }>({})
    const [corpusLoaded, setCorpusLoaded] = useState<boolean>(false)


    useEffect(() => {
        if (!textSettings) {
            return
        }
        const loadCorpusText = async () => {
            const newCorpusTextData: { [title: string]: CorpusTextData } = {}
            for (const x of textSettings) {
                const text = await fetchTextResource(x.file)
                const textAuth = await fetchTextResource(x.file_auth)
                // TODO: IMPROVE THIS - FIX ENCODING ISSUE FOR NON ENGLISH TEXT
                const splitText = text.split("\n").map(function (x) {
                    return x.substring(x.indexOf('\t') + 1).replace(/\0/g, '').trim()
                  }).filter(x => { return x.length > 0 })
           
                // TODO: IMPROVE THIS - FIX ENCODING ISSUE FOR NON ENGLISH TEXT
                const splittextAuth = textAuth.split("\n").map(function (x) {
                    return x.replace(/"/g, "").substring(x.indexOf('�') + 2).replace(/\0/g, '').trim()
                  }).filter(x => { return x.length > 0 })

                // Add authorization text as first item of corpus text
                splitText.unshift(splittextAuth[0])
                
                const data: CorpusTextData = {
                    title: x.title,
                    wavPrefix: x.wavPrefix,
                    file: x.file,
                    file_auth: x.file_auth,
                    text: splitText,
                }
                newCorpusTextData[data.title] = data
            }
            setCorpusTextData(newCorpusTextData)
            setCorpusLoaded(true)
        }
        loadCorpusText()
    }, [textSettings])


    return {
        corpusTextData,
        corpusLoaded,
    }
}
